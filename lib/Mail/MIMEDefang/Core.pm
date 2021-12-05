package Mail::MIMEDefang::Core;

require Exporter;

use Errno qw(ENOENT EACCES);
use File::Spec;
use Sys::Syslog;

my $_syslogopen = undef;

our @ISA = qw(Exporter);
our @EXPORT;
our @EXPORT_OK;

@EXPORT = qw{
      $AddWarningsInline @StatusTags
      $Action $Administrator $AdminName $AdminAddress $DoStatusTags
      $Changed $CSSHost $DaemonAddress $DaemonName
      $DefangCounter $Domain $EntireMessageQuarantined
      $MessageID $Rebuild $QuarantineCount
      $QuarantineSubdir $QueueID $MsgID $MIMEDefangID
      $RelayAddr $WasResent $RelayHostname
      $RealRelayAddr $RealRelayHostname
      $ReplacementEntity $Sender $ServerMode $Subject $SubjectCount
      $ClamdSock $SophieSock $TrophieSock
      $Helo @ESMTPArgs
      @SenderESMTPArgs %RecipientESMTPArgs
      $TerminateAndDiscard $URL $VirusName
      $CurrentVirusScannerMessage @AddedParts
      $VirusScannerMessages $WarningLocation $WasMultiPart
      $CWD $FprotdHost $Fprotd6Host
      $NotifySenderSubject $NotifyAdministratorSubject
      $ValidateIPHeader
      $QuarantineSubject $SALocalTestsOnly $NotifyNoPreamble
      %Actions %Stupidity @FlatParts @Recipients @Warnings %Features
      $SyslogFacility $GraphDefangSyslogFacility
      $MaxMIMEParts $InMessageContext $InFilterContext $PrivateMyHostName
      $EnumerateRecipients $InFilterEnd $FilterEndReplacementEntity
      $AddApparentlyToForSpamAssassin $WarningCounter
      @VirusScannerMessageRoutines @VirusScannerEntityRoutines
      $VirusScannerRoutinesInitialized
      %SendmailMacros %RecipientMailers $CachedTimezone $InFilterWrapUp
      $SuspiciousCharsInHeaders
      $SuspiciousCharsInBody
      $GeneralWarning
      $HTMLFoundEndBody $HTMLBoilerplate $SASpamTester
      $results_fh
      init_globals detect_and_load_perl_modules
      init_status_tag push_status_tag pop_status_tag
      signal_changed signal_unchanged md_syslog write_result_line
      in_message_context in_filter_context in_filter_wrapup in_filter_end
      percent_decode percent_encode percent_encode_for_graphdefang
    };

@EXPORT_OK = qw{
      read_config set_status_tag
    };

sub new {
    my ($class, @params) = @_;
    my $self = {};
    return bless $self, $class;
}

sub init_globals {
    my ($self, @params) = @_;

    $CWD = $Features{'Path:SPOOLDIR'};
    $InMessageContext = 0;
    $InFilterEnd = 0;
    $InFilterContext = 0;
    $InFilterWrapUp = 0;
    undef $FilterEndReplacementEntity;
    $Action = "";
    $Changed = 0;
    $DefangCounter = 0;
    $Domain = "";
    $MIMEDefangID = "";
    $MsgID = "NOQUEUE";
    $MessageID = "NOQUEUE";
    $Helo = "";
    $QueueID = "NOQUEUE";
    $QuarantineCount = 0;
    $Rebuild = 0;
    $EntireMessageQuarantined = 0;
    $QuarantineSubdir = "";
    $RelayAddr = "";
    $RealRelayAddr = "";
    $WasResent = 0;
    $RelayHostname = "";
    $RealRelayHostname = "";
    $Sender = "";
    $Subject = "";
    $SubjectCount = 0;
    $SuspiciousCharsInHeaders = 0;
    $SuspiciousCharsInBody = 0;
    $TerminateAndDiscard = 0;
    $VirusScannerMessages = "";
    $VirusName = "";
    $WasMultiPart = 0;
    $WarningCounter = 0;
    undef %Actions;
    undef %SendmailMacros;
    undef %RecipientMailers;
    undef %RecipientESMTPArgs;
    undef @FlatParts;
    undef @Recipients;
    undef @Warnings;
    undef @AddedParts;
    undef @StatusTags;
    undef @ESMTPArgs;
    undef @SenderESMTPArgs;
    undef $results_fh;
}

#***********************************************************************
# %PROCEDURE: md_syslog
# %ARGUMENTS:
#  facility -- Syslog facility as a string
#  msg -- message to log
# %RETURNS:
#  Nothing
# %DESCRIPTION:
#  Calls syslog, using Sys::Syslog package
#***********************************************************************
sub md_syslog
{
  my ($facility, $msg) = @_;

  if(!$_syslogopen) {
    md_openlog('mimedefang.pl', $SyslogFacility);
  }

  if (defined $MsgID && $MsgID ne 'NOQUEUE') {
    return Sys::Syslog::syslog($facility, '%s', $MsgID . ': ' . $msg);
  } else {
    return Sys::Syslog::syslog($facility, '%s', $msg);
  }
}

#***********************************************************************
# %PROCEDURE: md_openlog
# %ARGUMENTS:
#  tag -- syslog tag ("mimedefang.pl")
#  facility -- Syslog facility as a string
# %RETURNS:
#  Nothing
# %DESCRIPTION:
#  Opens a log using Sys::Syslog
#***********************************************************************
sub md_openlog
{
  my ($tag, $facility) = @_;
  return Sys::Syslog::openlog($tag, 'pid,ndelay', $facility);
}

# Detect these Perl modules at run-time.  Can explicitly prevent
# loading of these modules by setting $Features{"xxx"} = 0;
#
# You can turn off ALL auto-detection by setting
# $Features{"AutoDetectPerlModules"} = 0;

sub detect_and_load_perl_modules() {
    if (!defined($Features{"AutoDetectPerlModules"}) or
      $Features{"AutoDetectPerlModules"}) {
      if (!defined($Features{"SpamAssassin"}) or ($Features{"SpamAssassin"} eq 1)) {
        (eval 'use Mail::SpamAssassin (); $Features{"SpamAssassin"} = 1;')
        or $Features{"SpamAssassin"} = 0;
      }
      if (!defined($Features{"HTML::Parser"}) or ($Features{"HTML::Parser"} eq 1)) {
        (eval 'use HTML::Parser; $Features{"HTML::Parser"} = 1;')
        or $Features{"HTML::Parser"} = 0;
      }
      if (!defined($Features{"Archive::Zip"}) or ($Features{"Archive::Zip"} eq 1)) {
        (eval 'use Archive::Zip qw(:ERROR_CODES); $Features{"Archive::Zip"} = 1;')
        or $Features{"Archive::Zip"} = 0;
      }
      if (!defined($Features{"Net::DNS"}) or ($Features{"Net::DNS"} eq 1)) {
        (eval 'use Net::DNS; $Features{"Net::DNS"} = 1;')
        or $Features{"Net::DNS"} = 0;
      }
    }
}

#***********************************************************************
# %PROCEDURE: read_config
# %ARGUMENTS:
#  configuration file path
# %RETURNS:
#  return 1 if configuration file cannot be loaded; 0 otherwise
# %DESCRIPTION:
#  loads a configuration file to overwrite global variables values
#***********************************************************************
# Derivative work from amavisd-new read_config_file($$)
# Copyright (C) 2002-2018 Mark Martinec
sub read_config($) {
  my($config_file) = @_;

  $config_file = File::Spec->rel2abs($config_file);

  my(@stat_list) = stat($config_file);  # symlinks-friendly
  my $errn = @stat_list ? 0 : 0+$!;
  my $owner_uid = $stat_list[4];
  my $msg;

  if ($errn == ENOENT) { $msg = "does not exist" }
  elsif ($errn)        { $msg = "is inaccessible: $!" }
  elsif (-d _)         { $msg = "is a directory" }
  elsif (-S _ || -b _ || -c _) { $msg = "is not a regular file or pipe" }
  elsif ($owner_uid) { $msg = "should be owned by root (uid 0)" }
  if (defined $msg)    {
    return (1, $msg);
  }
  if (defined(do $config_file)) {}
  return (0, undef);
}

# Try to open the status descriptor
sub init_status_tag
{
	return unless $DoStatusTags;

	if(open(STATUS_HANDLE, ">&=3")) {
		STATUS_HANDLE->autoflush(1);
	} else {
		$DoStatusTags = 0;
	}
}

#***********************************************************************
# %PROCEDURE: set_status_tag
# %ARGUMENTS:
#  nest_depth -- nesting depth
#  tag -- status tag
# %DESCRIPTION:
#  Sets the status tag for this worker inside the multiplexor.
# %RETURNS:
#  Nothing
#***********************************************************************
sub set_status_tag
{
	return unless $DoStatusTags;

	my ($depth, $tag) = @_;
	$tag ||= '';

	if($tag eq '') {
		print STATUS_HANDLE "\n";
		return;
	}
	$tag =~ s/[^[:graph:]]/ /g;

	if(defined($MsgID) and ($MsgID ne "NOQUEUE")) {
		print STATUS_HANDLE percent_encode("$depth: $tag $MsgID") . "\n";
	} else {
		print STATUS_HANDLE percent_encode("$depth: $tag") . "\n";
	}
}

#***********************************************************************
# %PROCEDURE: push_status_tag
# %ARGUMENTS:
#  tag -- tag describing current status
# %DESCRIPTION:
#  Updates status tag inside multiplexor and pushes onto stack.
# %RETURNS:
#  Nothing
#***********************************************************************
sub push_status_tag
{
	return unless $DoStatusTags;

	my ($tag) = @_;
	push(@StatusTags, $tag);
	if($tag ne '') {
		$tag = "> $tag";
	}
	set_status_tag(scalar(@StatusTags), $tag);
}

#***********************************************************************
# %PROCEDURE: pop_status_tag
# %ARGUMENTS:
#  None
# %DESCRIPTION:
#  Pops previous status of stack and sets tag in multiplexor.
# %RETURNS:
#  Nothing
#***********************************************************************
sub pop_status_tag
{
	return unless $DoStatusTags;

	pop @StatusTags;

	my $tag = $StatusTags[0] || 'no_tag';

	set_status_tag(scalar(@StatusTags), "< $tag");
}

#***********************************************************************
# %PROCEDURE: percent_encode
# %ARGUMENTS:
#  str -- a string, possibly with newlines and control characters
# %RETURNS:
#  A string with unsafe chars encoded as "%XY" where X and Y are hex
#  digits.  For example:
#  "foo\r\nbar\tbl%t" ==> "foo%0D%0Abar%09bl%25t"
#***********************************************************************
sub percent_encode {
  my($str) = @_;

  $str =~ s/([^\x21-\x7e]|[%\\'"])/sprintf("%%%02X", unpack("C", $1))/ge;
  #" Fix emacs highlighting...
  return $str;
}

#***********************************************************************
# %PROCEDURE: percent_encode_for_graphdefang
# %ARGUMENTS:
#  str -- a string, possibly with newlines and control characters
# %RETURNS:
#  A string with unsafe chars encoded as "%XY" where X and Y are hex
#  digits.  For example:
#  "foo\r\nbar\tbl%t" ==> "foo%0D%0Abar%09bl%25t"
# This differs slightly from percent_encode because we don't encode
# quotes or spaces, but we do encode commas.
#***********************************************************************
sub percent_encode_for_graphdefang {
  my($str) = @_;
  $str =~ s/([^\x20-\x7e]|[%\\,])/sprintf("%%%02X", unpack("C", $1))/ge;
  #" Fix emacs highlighting...
  return $str;
}

#***********************************************************************
# %PROCEDURE: percent_decode
# %ARGUMENTS:
#  str -- a string encoded by percent_encode
# %RETURNS:
#  The decoded string.  For example:
#  "foo%0D%0Abar%09bl%25t" ==> "foo\r\nbar\tbl%t"
#***********************************************************************
sub percent_decode {
  my($str) = @_;
  $str =~ s/%([0-9A-Fa-f]{2})/pack("C", hex($1))/ge;
  return $str;
}

=pod

=head2 write_result_line ( $cmd, @args )

Writes a result line to the RESULTS file.

$cmd should be a one-letter command for the RESULTS file

@args are the arguments for $cmd, if any.  They will be percent_encode()'ed
before being written to the file.

Returns 0 or 1 and an optional warning message.

=cut

sub write_result_line
{
        my $cmd = shift;

        # Do nothing if we don't yet have a dedicated working directory
        if ($CWD eq $Features{'Path:SPOOLDIR'}) {
                md_syslog('warning', "write_result_line called before working directory established");
                return;
        }

        my $line = $cmd . join ' ', map { percent_encode($_) } @_;

        if (!$results_fh) {
                $results_fh = IO::File->new('>>RESULTS');
                if (!$results_fh) {
                        die("Could not open RESULTS file: $!");
                }
        }

        # We have a 16kb limit on the length of lines in RESULTS, including
        # trailing newline and null used in the milter.  So, we limit $cmd +
        # $args to 16382 bytes.
        if( length $line > 16382 ) {
                md_syslog( 'warning',  "Cannot write line over 16382 bytes long to RESULTS file; truncating.  Original line began with: " . substr $line, 0, 40);
                $line = substr $line, 0, 16382;
        }

        print $results_fh "$line\n" or die "Could not write RESULTS line: $!";

        return;
}

#***********************************************************************
# %PROCEDURE: signal_unchanged
# %ARGUMENTS:
#  None
# %RETURNS:
#  Nothing
# %DESCRIPTION:
#  Tells mimedefang C program message has not been altered (does nothing...)
#***********************************************************************
sub signal_unchanged {
}

#***********************************************************************
# %PROCEDURE: signal_changed
# %ARGUMENTS:
#  None
# %RETURNS:
#  Nothing
# %DESCRIPTION:
#  Tells mimedefang C program message has been altered.
#***********************************************************************
sub signal_changed {
    write_result_line("C", "");
}

#***********************************************************************
# %PROCEDURE: in_message_context
# %ARGUMENTS:
#  name -- a string to syslog if we are not in a message context
# %RETURNS:
#  1 if we are processing a message; 0 otherwise.  Returns 0 if
#  we're in filter_relay, filter_sender or filter_recipient
#***********************************************************************
sub in_message_context {
    my($name) = @_;
    return 1 if ($InMessageContext);
    md_syslog('warning', "$name called outside of message context");
    return 0;
}

#***********************************************************************
# %PROCEDURE: in_filter_wrapup
# %ARGUMENTS:
#  name -- a string to syslog if we are in filter wrapup
# %RETURNS:
#  1 if we are not in filter wrapup; 0 otherwise.
#***********************************************************************
sub in_filter_wrapup {
    my($name) = @_;
    if ($InFilterWrapUp) {
	    md_syslog('warning', "$name called inside filter_wrapup context");
	    return 1;
    }
    return 0;
}

#***********************************************************************
# %PROCEDURE: in_filter_context
# %ARGUMENTS:
#  name -- a string to syslog if we are not in a filter context
# %RETURNS:
#  1 if we are inside filter or filter_multipart, 0 otherwise.
#***********************************************************************
sub in_filter_context {
    my($name) = @_;
    return 1 if ($InFilterContext);
    md_syslog('warning', "$name called outside of filter context");
    return 0;
}

#***********************************************************************
# %PROCEDURE: in_filter_end
# %ARGUMENTS:
#  name -- a string to syslog if we are not in filter_end
# %RETURNS:
#  1 if we are inside filter_end 0 otherwise.
#***********************************************************************
sub in_filter_end {
    my($name) = @_;
    return 1 if ($InFilterEnd);
    md_syslog('warning', "$name called outside of filter_end");
    return 0;
}

1;