use v6;
use LibCurl::HTTP;
use Getopt::Long;

use lib 'lib';
use Keys;

sub MAIN(
    $input, # filepath of lo file or string of single log
    Str :e(:$env) = "us" # String; defines which instance (EU, US etc.) to send the logs to
) {

    # TODO - add better way to pass env variables into sub modules
    send_message($env, $input);

}

sub send_message ($env, $input) {
    my $KEY;
    my $endpoint = $HTTP_ENDPOINT;
    my $domain;
    my $curl = LibCurl::HTTP.new;


    given $env {
        when 'eu' {
            $domain = 'eu';
            $KEY = $DD_API_KEY;
        }
        when 'us' {
            $domain = 'com';
            $KEY = $DD_API_KEY_EU;
        }
        when 'staging' {
            $endpoint = $STAGING_ENDPOINT;
            $domain = 'com';
            $KEY = $DD_API_KEY_STAGING;
        }
    }

    given $input {
        # Do some stuff when input is a file
        when $input.IO ~~ :f {

            my $logs = slurp($input.IO);

            # We can set the size of the payload here
            # $curl.setopt(postfieldsize => <size>);

            $curl.set-header(content-type => 'text/plain');
            $curl.setopt(URL => "https://$endpoint.$domain/v1/input/$KEY", postfields => $logs);
        }
        # Do some stuff when input is a string
        when Str {
            
            $curl.set-header(content-type => 'application/json');
            $curl.setopt(URL => "https://$endpoint.$domain/v1/input/$KEY", postfields => $input);

        }
    }

    $curl.perform;
    say $curl.response-code;

}

# TODO - accept a list of tags (service, source etc.) and apply them in the url
# sub parse_tags ($tags) {
# }

# Referenc doc : 
# https://github.com/DataDog/browser-sdk/blob/9acbda2858cf11f2eeefd7bcbf165795195069b5/packages/core/src/configuration.ts#L113-L119
# curl -X POST "https://browser-http-intake.logs.datadoghq.com/v1/input/<CLIENT_TOKEN>?service=testing&ddsource=testing" -H "Content-Type: application/json" -d '{"message":"this is a test"}'
