=head1 NAME

Integrations::Whitespace - Whitespace Work Software API integration

=head1 DESCRIPTION

This module provides an interface to the Whitespace Work Software Web Services API

=cut

package Integrations::Whitespace;

use strict;
use warnings;
use Moo;

use FixMyStreet;

use SOAP::Lite; # +trace => [qw(debug)];

with 'FixMyStreet::Roles::SOAPIntegration';
with 'FixMyStreet::Roles::ParallelAPI';

has attr => ( is => 'ro', default => 'http://webservices.whitespacews.com/' );
has username => ( is => 'ro' );
has password => ( is => 'ro' );
has url => ( is => 'ro' );
has sample_data => ( is => 'ro', default => 0 );

has endpoint => (
    is => 'lazy',
    default => sub {
        my $self = shift;

        $ENV{PERL_LWP_SSL_CA_PATH} = '/etc/ssl/certs' unless $ENV{DEV_USE_SYSTEM_CA_PATH};

        SOAP::Lite->new(
            soapversion => 1.1,
            proxy => $self->url,
            default_ns => $self->attr,
            on_action => sub { $self->attr . $_[1] }
        );
    },
);

has security => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        SOAP::Header->name("Security")->attr({
            'mustUnderstand' => 'true',
            'xmlns' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
        })->value(
            \SOAP::Header->name(
                "UsernameToken" => \SOAP::Header->value(
                    SOAP::Header->name('Username', $self->username),
                    SOAP::Header->name('Password', $self->password),
                )
            )
        );
    },
);

has backend_type => ( is => 'ro', default => 'whitespace' );

sub call {
    my ($self, $method, @params) = @_;

    require SOAP::Lite;
    @params = make_soap_structure(@params);
    my $som = $self->endpoint->call(
        $method => @params,
        $self->security
    );

    # TODO: Better error handling
    die $som->faultstring if ($som->fault);

    return $som->result;
}

sub GetAddresses {
    my ($self, $postcode) = @_;

    my $res = $self->call('GetAddresses', getAddressInput => ixhash( Postcode => $postcode ));

    my $addresses = force_arrayref($res->{Addresses}, 'Address');

    return $addresses;
}

sub GetSiteCollections {
    my ($self, $uprn) = @_;

    my $res = $self->call('GetSiteCollections', siteserviceInput => ixhash( Uprn => $uprn ));

    my $site_services = force_arrayref($res->{SiteServices}, 'SiteService');

    return $site_services;
}

sub GetSiteInfo {
    my ( $self, $account_site_id ) = @_;

    my $res = $self->call('GetSiteInfo', siteInfoInput => ixhash( AccountSiteId => $account_site_id ));

    return $res->{Site};
}

sub GetAccountSiteID {
    my ( $self, $site_id ) = @_;

    my $res = $self->call( 'GetAccountSiteId',
        siteInput => ixhash( SiteId => $site_id ) );

    return $res;
}

sub GetSiteServiceItemRoundSchedules {
    my ($self, $site_service_id) = @_;

    my $res = $self->call('GetSiteServiceItemRoundSchedules', siteServiceItemRoundScheduleInput => ixhash( SiteServiceId => $site_service_id ));

    return $res->{RRASSContractRounds}->{RRASSContractRound};
}

sub GetSiteWorksheets {
    my ($self, $uprn) = @_;

    my $res = $self->call('GetSiteWorksheets', worksheetInput => ixhash( Uprn => $uprn ));

    return $res;
}

sub GetCollectionByUprnAndDatePlus {
    my ($self, $uprn, $date_from, $date_to) = @_;

    my $res = $self->call('GetCollectionByUprnAndDatePlus', getCollectionByUprnAndDatePlusInput => ixhash( Uprn => $uprn, NextCollectionFromDate => $date_from, NextCollectionToDate => $date_to ));

    # TODO Need to force arrayref?
    return $res->{Collections}{Collection};
}

sub GetInCabLogsByUsrn {
    my ($self, $usrn, $log_from_date) = @_;

    my $res = $self->call('GetInCabLogs', inCabLogInput => ixhash( Usrn => $usrn, LogFromDate => $log_from_date, LogTypeID => [] ));

    return $res->{InCabLogs}->{InCabLogs};
}

sub GetInCabLogsByUprn {
    my ($self, $uprn, $log_from_date) = @_;

    my $res = $self->call('GetInCabLogs', inCabLogInput => ixhash( Uprn => $uprn, LogFromDate => $log_from_date, LogTypeID => [] ));

    return $res->{InCabLogs}->{InCabLogs};
}

sub GetStreets {
    my ($self, $postcode) = @_;

    my $res = $self->call('GetStreets', getStreetInput => ixhash( streetName => '', townName => '', postcode => $postcode ));

    my $streets = force_arrayref($res->{StreetArray}, 'Street');

    return $streets;
}


sub GetSiteIncidents {
    my ($self, $uprn) = @_;

    my $res = $self->call('GetSiteIncidents', roundIncidentInput => ixhash( Uprn => $uprn ));

    return $res->{RoundIncidents}->{RoundIncidents};
}

sub GetSiteContracts {
    my ($self, $uprn) = @_;

    my $res = $self->call('GetSiteContracts', sitecontractInput => ixhash( Uprn => $uprn ));

    return $res->{SiteContracts}->{SiteContract};
}

1;
