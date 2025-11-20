"""Strato API for DNS manipulation."""
import typing


class StratoDnsApiCredentials:
    """Class to hold Strato DNS API credentials."""

    @staticmethod
    def from_dict(
            data: dict,
        ) -> 'StratoDnsApiCredentials':
        """Initialize Strato DNS API credentials from dictionary.

        :param dict data: Dictionary with credentials

        :returns: StratoDnsApiCredentials instance
        :rtype: StratoDnsApiCredentials

        """
        return StratoDnsApiCredentials(
            username=data['username'],
            password=data['password'],
            totp_secret=data.get('totp_secret'),
            totp_devicename=data.get('totp_devicename'),
        )

    @property
    def username(self) -> str:
        return self._username
    @property
    def password(self) -> str:
        return self._password
    @property
    def totp_secret(self) -> typing.Optional[str]:
        return self._totp_secret
    @property
    def totp_devicename(self) -> typing.Optional[str]:
        return self._totp_devicename
    @property
    def logged_in(self) -> bool:
        return self._logged_in
    @logged_in.setter
    def logged_in(self, value: bool):
        self._logged_in = value

    def __init__(
            self,
            username: str,
            password: str,
            totp_secret: typing.Optional[str] = None,
            totp_devicename: typing.Optional[str] = None,
        ):

        self._username = username
        self._password = password
        self._totp_secret = totp_secret
        self._totp_devicename = totp_devicename
        
        self._logged_in = False