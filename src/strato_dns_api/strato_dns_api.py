"""Strato API for DNS manipulation."""
import sys
import re
import logging
import typing
import json

# Third party imports
import urllib
import pyotp
import requests
from bs4 import BeautifulSoup
import tldextract

from strato_dns_api.strato_dns_api_credentials import StratoDnsApiCredentials

class StratoDnsApi:
    """Class to manipulate DNS on domains hosted at Strato"""

    API_URLS = {
        "de": "https://www.strato.de/apps/CustomerService",
        "nl": "https://www.strato.nl/apps/CustomerService#skl",
    }

    BASE_DOMAIN_REGEX = re.compile(r'([\w-]+\.[\w-]+)$')
    RECORD_PREFIX_REGEX = re.compile(r'^([\w-]+)')

    @staticmethod
    def from_config_file(
            config_file: str,
            log_level: int = logging.INFO,
        ) -> 'StratoDnsApi':
        """Initialize Strato DNS API from JSON config file.

        :param str config_file: Path to JSON config file
        :param int log_level: Logging level

        :returns: StratoDnsApiCredentials instance
        :rtype: StratoDnsApiCredentials

        """
        logging.basicConfig(level=log_level)
        logger = logging.getLogger('strato_dns_api')
        logger.info(f'Loading configuration from {config_file}...')
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                if not "location" in config:
                    config["location"] = "de"
                    logger.info('No location specified in config, defaulting to "de"')
            
                api = StratoDnsApi(location=config["location"], credentials=StratoDnsApiCredentials.from_dict(config['credentials']), log_level=log_level)
                
                logger.info('Configuration loaded successfully.')
                return api
                
        except Exception as e:
           logger.error(f'Error loading config file {config_file}: {e}')
           sys.exit(1)

    def __init__(self, location: str, credentials: StratoDnsApiCredentials, log_level=logging.INFO):

        self._logger = logging.getLogger(self.__class__.__name__)
        logfmt = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        loghdlr = logging.StreamHandler(stream=sys.stdout)
        loghdlr.setFormatter(logfmt)
        self._logger.addHandler(loghdlr)
        self._logger.setLevel(log_level)

        self._credentials = credentials
        if not location in self.API_URLS:
            self._logger.error(f'Unsupported location "{location}", available: {list(self.API_URLS.keys())}')
            sys.exit(1)

        self._api_url = self.API_URLS[location]

        # setup session for cookie sharing
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:126.0) Gecko/20100101 Firefox/126.0'}
        self._http_session = requests.session()
        self._http_session.headers.update(headers)
        self._session_id = ''

    def login(self) -> bool:
        """Login to Strato website. Requests session ID.

        :returns: True if login was successful
        :rtype: bool

        """
        if self._credentials.logged_in:
            self._logger.debug('Already logged in.')
            return True

        self._logger.info(f'Logging in to {self._api_url}...')
        # request session id
        self._http_session.get(self._api_url)
        data={'identifier': self._credentials.username, 'passwd': self._credentials.password, 'action_customer_login.x': 'Login'}

        request = self._http_session.post(self._api_url, data=data)

        # Check 2FA Login (if required)
        request = self._login_2fa(request, self._credentials.username,
            self._credentials.totp_secret, self._credentials.totp_devicename)

        # Check successful login
        parsed_url = urllib.parse.urlparse(request.url)
        query_parameters = urllib.parse.parse_qs(parsed_url.query)
        if 'sessionID' not in query_parameters:
            self._logger.error('Login failed. No session ID found.')
            self._credentials.logged_in = False
            return False
        else:
            self._session_id = query_parameters['sessionID'][0]
            self._logger.debug(f'session_id: {self._session_id}')
            self._logger.info('Login successful.')
            self._credentials.logged_in = True
            return True

    def get_txt_records(self, full_domain:str, package_id: typing.Optional[int] = None) -> list[dict]:
        """Requests all txt and cname records related to domain."""

        self._logger.info(f'Getting TXT/CNAME records for domain: {full_domain}')

        root_domain, _ = self._get_root_domain(full_domain)

        if not self.login():
            self._logger.error('Cannot get TXT records, not logged in.')
            return []

        request = self._http_session.get(self._api_url, params={
            'sessionID': self._session_id,
            'cID': self._load_package_id(root_domain) if not package_id else package_id,
            'node': 'ManageDomains',
            'action_show_txt_records': '',
            'vhost': root_domain
        })

        records = []
        # No idea what this regex does
        # TODO: rewrite with beautifulsoup
        for record in re.finditer(
                r'<select [^>]*name="type"[^>]*>.*?'
                r'<option[^>]*value="(?P<type>[^"]*)"[^>]*selected[^>]*>'
                r'.*?</select>.*?'
                r'<input [^>]*value="(?P<prefix>[^"]*)"[^>]*name="prefix"[^>]*>'
                r'.*?<textarea [^>]*name="value"[^>]*>(?P<value>.*?)</textarea>',
                request.text):
            records.append({
                'prefix': record.group('prefix'),
                'type': record.group('type'),
                'value': record.group('value')
            })

        self._logger.debug(f"Current cname/txt records for '{root_domain}':")
        list(self._logger.debug(f'  {item["type"]}: {item["prefix"]}.{root_domain} = {item["value"]}')
            for item in records)
        
        return records

    def add_txt_record(self, full_domain:str, record_type: str, value: str, overwrite: bool = False) -> bool:
        """Add a txt/cname record.

        :param key str: Key of record as FQDN or prefix, eg 'subdomain' or 'subdomain.domain.tld'
        :param record_type str: Type of record ('TXT' or 'CNAME')
        :param value str: Value of record
        :param records dict: Existing records to modify, if None fetches current records
        :param overwrite bool: Whether to overwrite existing records or add a new one

        """
        
        root_domain, prefix = self._get_root_domain(full_domain)

        if not self.login():
            self._logger.error('Cannot add TXT record, not logged in.')
            return False

        package_id = self._load_package_id(root_domain)
        records = self.get_txt_records(root_domain, package_id)

        if any(r['prefix'] == prefix and r['type'] == record_type for r in records):
            if overwrite:
                self._logger.info(f'Overwriting existing {record_type} record: {prefix} = {value}...')
                for record in records:
                    if record['prefix'] == prefix and record['type'] == record_type:
                        record['value'] = value
                        break
            else:
                self._logger.info(f'Creating additional {record_type} record: {prefix} = {value}')
        else:
            self._logger.info(f'Creating new {record_type} record: {prefix} = {value}...')
        
        records.append({
            'prefix': prefix,
            'type': record_type,
            'value': value,
        })

        if self._push_txt_records(records, root_domain, package_id):
            self._logger.info(f'Successfully added {record_type} record: {prefix}')
            return True
        else:
            self._logger.error(f'Failed to add {record_type} record: {prefix}')
            return False


    def remove_txt_record(self, full_domain:str, record_type: str, value: typing.Optional[str] = None) -> bool:
        """Remove a txt/cname record.

        :param full_domain str: Key of record as FQDN or prefix, eg 'subdomain' or 'subdomain.domain.tld'
        :param record_type str: Type of record ('TXT' or 'CNAME')
        :param value str: Value to remove from record, if None removes all records with matching prefix

        """
        # sanitize the prefix
        root_domain, prefix = self._get_root_domain(full_domain)

        if not self.login():
            self._logger.error('Cannot remove record, not logged in.')
            return False

        package_id = self._load_package_id(root_domain)
        records = self.get_txt_records(root_domain, package_id)

        self._logger.info(f'Removing {record_type} record: {prefix}')

        for i in reversed(range(len(records))):
            if (records[i]['prefix'] == prefix
                and records[i]['type'] == record_type):
                if value and value in records[i]['value']:
                    self._logger.info(f"Removing value from {record_type} record: {prefix} -= {value}")
                    records[i]['value'] = records[i]['value'].replace(value, '').strip()
                else:
                    records.pop(i)
                if self._push_txt_records(records, root_domain, package_id):
                    self._logger.info(f'Removed {record_type} record: {prefix}')
                    return True
                else:
                    self._logger.error(f'Failed to remove {record_type} record: {prefix}')
                    return False

        self._logger.warning(f'No {record_type} record found for removal: {prefix}')
        return True

#######################################################################################################################
# private methods
    def _login_2fa(
            self,
            response: requests.Response,
            username: str,
            totp_secret: typing.Optional[str],
            totp_devicename: typing.Optional[str],
            ) -> requests.Response:
        """Login with Two-factor authentication by TOTP on Strato website.

        :param str totp_secret: 2FA TOTP secret hash
        :param str totp_devicename: 2FA TOTP device name

        :returns: Original response or 2FA response
        :rtype: requests.Response

        """
        # Is 2FA used
        soup = BeautifulSoup(response.text, 'html.parser')
        if soup.find('h1', string=re.compile('Zwei\\-Faktor\\-Authentifizierung')) is None:
            self._logger.info('2FA is not used.')
            return response
        if (not totp_secret) or (not totp_devicename):
            self._logger.error('2FA parameter is not completely set.')
            return response

        param = {'identifier': username}

        # Set parameter 'totp_token'
        totp_input = soup.find('input', attrs={'type': 'hidden', 'name': 'totp_token'})
        if totp_input is not None:
            param['totp_token'] = totp_input['value']
        else:
            self._logger.error('Parsing error on 2FA site by totp_token.')
            return response

        # Set parameter 'action_customer_login.x'
        param['action_customer_login.x'] = 1

        # No idea what this regex does
        # TODO: rewrite with beautifulsoup
        # Set parameter pw_id
        for device in re.finditer(
            rf'<option value="(?P<value>(S\.{username}\.\w*))"'
            r'( selected(="selected")?)?\s*>(?P<name>(.+?))</option>',
            response.text):
            if totp_devicename.strip() == device.group('name').strip():
                param['pw_id'] = device.group('value')
                break
        if param.get('pw_id') is None:
            self._logger.error('Parsing error on 2FA site by device name.')
            return response

        # Set parameter 'totp'
        param['totp'] = pyotp.TOTP(totp_secret).now()
        self._logger.debug(f'totp: {param.get("totp")}')

        request = self._http_session.post(self._api_url, param)
        return request

    def _push_txt_records(self, records: list[dict], root_domain: str, package_id: int) -> bool:
        """Push modified txt records to Strato."""
        self._logger.debug('Pushing domain TXT/CNAME records:')
        list(self._logger.debug(f'  {item["type"]}: {item["prefix"]}.{root_domain} = {item["value"]}')
            for item in records)

        result = self._http_session.post(self._api_url, {
            'sessionID': self._session_id,
            'cID': package_id,
            'node': 'ManageDomains',
            'vhost': root_domain,
            'spf_type': 'NONE',
            'prefix': [r['prefix'] for r in records],
            'type': [r['type'] for r in records],
            'value': [r['value'] for r in records],
            'action_change_txt_records': 'Einstellung+übernehmen',
        })

        return True if result.status_code == 200 else False

    def _load_package_id(self, root_domain:str) -> int:
        """Requests package ID for the selected domain.

        :param str root_domain: Root domain to search for
        :param str session_id: Session ID from login
        :param int package_id: Predefined package ID

        :returns: Package ID on success, 1 as default otherwise
        :rtype: int
        """
        # request strato packages
        request = self._http_session.get(self._api_url, params={
            'sessionID': self._session_id,
            'cID': 0,
            'node': 'kds_CustomerEntryPage',
        })
        soup = BeautifulSoup(request.text, 'html.parser')
        package_anchor = soup.select_one(
            '#package_list > tbody >'
            f' tr:has(.package-information:-soup-contains("{root_domain}"))'
            ' .jss_with_own_packagename a'
        )
        if package_anchor:
            if package_anchor.has_attr('href'):
                link_target = urllib.parse.urlparse(package_anchor["href"])
                package_id = urllib.parse.parse_qs(link_target.query)["cID"][0]
                self._logger.debug(f'strato package id (cID): {package_id}')
                return package_id
        
        self._logger.error(f'Domain {root_domain} not '
            'found in strato packages. Using fallback cID=1')
        return 1
    
    def _get_root_domain(self, full_domain:str) -> tuple[str, str]:
        """
        Returns (root_domain, subdomain) for any ACME DNS-01 FQDN such as:
        _acme-challenge.example.com
        _acme-challenge.www.example.co.uk
        sub1.sub2.example.co.uk
        """

        ext = tldextract.extract(full_domain)

        # Build the root domain (registrable domain)
        root = f"{ext.domain}.{ext.suffix}" if ext.suffix else ext.domain

        # Subdomain may be empty
        sub = ext.subdomain or ""

        return root, sub