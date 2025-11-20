import sys
import os
import click
import logging

from strato_dns_api.strato_dns_api import StratoDnsApi

@click.group()
@click.option('--config', '-c', type=click.Path(exists=True), required=True, help='Path to configuration file')
@click.option('--log-level', '-l', type=click.Choice([level for level,_ in logging.getLevelNamesMapping().items()]), help='Logging level')
@click.pass_context
def cli(ctx, config, log_level):
    """Strato DNS API command line interface."""
    api = StratoDnsApi.from_config_file(config, log_level=logging.getLevelNamesMapping().get(log_level, logging.INFO))
    
    ctx.ensure_object(dict)
    ctx.obj['API'] = api

@cli.command()
@click.option('--domain', '-n', required=True, help='Full domain name to get records for')
@click.pass_context
def get_records(ctx, domain):
    """Get DNS records."""
    api: StratoDnsApi = ctx.obj['API']

    records = api.get_txt_records(domain)
    click.echo(f"Records for {domain}: {records}")

@cli.command()
@click.option('--record-type', '-t', type=click.Choice(['CNAME', 'TXT']), required=True, help='Type of DNS record to add')
@click.option('--domain', '-n', required=True, help='Full domain name for the DNS record')
@click.option('--value', '-v', required=True, help='Value of the DNS record')
@click.option('--overwrite', is_flag=True, help='Overwrite existing record if it exists')
@click.pass_context
def add_record(ctx, record_type, domain, value, overwrite):
    """Add a DNS record."""
    api: StratoDnsApi = ctx.obj['API']
    
    success = api.add_txt_record(full_domain=domain, record_type=record_type, value=value, overwrite=overwrite)
    
    sys.exit(0 if success else 1)

@cli.command()
@click.option('--domain', '-n', required=True, help='Full domain name for the DNS record to delete')
@click.option('--record-type', '-t', type=click.Choice(['CNAME', 'TXT']), required=True, help='Type of DNS record to delete')
@click.option('--value', '-v', help='Value of the DNS record to delete (optional)', default=None)
@click.pass_context
def del_record(ctx, domain, record_type, value):
    """Delete a DNS record."""
    api: StratoDnsApi = ctx.obj['API']
    
    success = api.remove_txt_record(full_domain=domain, record_type=record_type, value=value)
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    cli()