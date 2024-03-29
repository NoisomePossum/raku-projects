use v6;
use LibCurl::HTTP;

use lib $?FILE.IO.parent.child('lib');
use Keys;

sub MAIN(
    $input, # filepath of lo file or string of single log
    Str :e(:$env) = "us", # String; defines which instance (eu, us, staging) to send the logs to
    Str :src(:$source) = "cli", # Overrides the default source value
    Str :ser(:$service) = "custom", # Overrides the default service value
    Str :h(:$host), # Adds a host
    Str :t(:$tags), # Add tags with comma-separated string of key/vaue pairs. Ex: key1:value1,key2:value2
    Bool :$nodef = False # Deactivates default values for source and service.
) {

    my %options = input => $input, env => $env, source => $source, service => $service, host => $host, tags => $tags, nodef => $nodef;

    send_message(%options);

}

sub send_message (%options) {

    my $curl = LibCurl::HTTP.new;

    my $URL = getURL(%options);

    # If input is a file stringify its contents and set header to plain text.
    if %options{'input'}.IO ~~ :f {

        %options{'input'} = slurp(%options{'input'}.IO);

        $curl.set-header(content-type => 'text/plain');
    }
    # If input is not a file (plain string) set header to application/json.
    else {
        
        $curl.set-header(content-type => 'application/json');

    }

    $curl.setopt(URL => "$URL", postfields => %options{'input'});
    $curl.perform;
    say $curl.response-code;
    say $curl.statusline;

}

sub getParams ($KEY, %options) {

    my $logparams = $KEY;

    if !%options{'nodef'} {
        $logparams = "$logparams?ddsource=%options{'source'}&service=%options{'service'}";
    }
    else {
      $logparams = "$logparams?";
    }

    if %options{'host'} {
        $logparams = "$logparams&host=%options{'host'}";
    }
    if %options{'tags'} {
        $logparams = "$logparams&ddtags=%options{'tags'}";
    }

    $logparams;
}

sub getURL (%options) {
    
    my $endpoint;
    my $domain;
    my $KEY;

    given %options{'env'} {
        when 'eu' {
            $endpoint = $HTTP_ENDPOINT;
            $domain = 'eu';
            $KEY = $DD_API_KEY_EU;
        }
        when 'us' {
            $endpoint = $HTTP_ENDPOINT;
            $domain = 'com';
            $KEY = $DD_API_KEY;
        }
        when 'staging' {
            $endpoint = $STAGING_ENDPOINT;
            $domain = 'com';
            $KEY = $DD_API_KEY_STAGING;
        }
    }

    my $logparams = getParams($KEY, %options);

    my $URL = "https://$endpoint.$domain/v1/input/$logparams";

}
