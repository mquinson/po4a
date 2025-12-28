use warnings;
use strict;

use Test::More tests => 12;
use Symbol           qw(gensym);
use IPC::Open3       qw(open3);
use Locale::Po4a::Po qw();

subtest 'no context' => sub {
    plan tests => 3;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw(
        msgid  => "msgid1",
        msgstr => "msgstr1",
        flags  => "wrap",
    );
    ok( defined $po->{po}{msgid1}{''} );
    is( $po->{po}{msgid1}{''}{msgstr}, "msgstr1" );
    is( $po->{po}{msgid1}{''}{flags},  "wrap" );
};

subtest 'push_raw subroutine / basic' => sub {
    plan tests => 2;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw(
        msgid   => "",
        msgstr  => "msgstr2",
        comment => "comment2",
    );
    is( $po->{header},         "msgstr2" );
    is( $po->{header_comment}, "comment2" );
};

subtest 'each_message' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw( msgid => 'id1', msgstr => 'str1' );
    my @messages;
    $po->each_message( sub { push @messages, \@_ } );
    is_deeply(
        \@messages,
        [
            [
                'id1',
                {
                    'pos_doc'   => [0],
                    'type'      => undef,
                    'previous'  => undef,
                    'comment'   => undef,
                    'pos'       => 0,
                    'automatic' => undef,
                    'msgstr'    => 'str1'
                }
            ]
        ]
    );
};

subtest 'replant subroutine' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw( msgid => 'id1', msgstr => 'str1' );
    $po->replant( 'id1', 'id3' );
    is_deeply(
        $po->{po},
        {
            'id3' => {
                '' => {
                    'previous'  => undef,
                    'automatic' => undef,
                    'pos_doc'   => [0],
                    'msgstr'    => 'str1',
                    'type'      => undef,
                    'pos'       => 0,
                    'comment'   => undef,
                }
            }
        }
    );
};

subtest 'message_by_document_position subroutine' => sub {
    plan tests => 3;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw( msgctxt => 'context1', msgid => 'id1', msgstr => 'str1' );
    my ( $msgid, $msgctxt, $message ) = $po->message_by_document_position(0);
    is( $msgid,   "id1" );
    is( $msgctxt, 'context1' );
    is_deeply(
        $message,
        {
            'comment'   => undef,
            'pos_doc'   => [0],
            'previous'  => undef,
            'pos'       => 0,
            'automatic' => undef,
            'type'      => undef,
            'msgstr'    => 'str1',
        }
    );
};

subtest 'message_by_msgid subroutine' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw( msgid => 'id1', msgstr => 'str1' );
    my $actual_message   = $po->message_by_msgid('id1');
    my %expected_message = (
        'previous'  => undef,
        'type'      => undef,
        'msgstr'    => 'str1',
        'comment'   => undef,
        'pos_doc'   => [0],
        'automatic' => undef,
        'pos'       => 0,
    );
    is_deeply( $actual_message, \%expected_message, );
};

subtest 'push_raw subroutine' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw(
        msgctxt => 'msgctxt1',
        msgid   => 'msgid1',
        msgstr  => 'msgstr1',
    );
    is_deeply(
        $po->{po},
        {
            'msgid1' => {
                'msgctxt1' => {
                    'automatic' => undef,
                    'comment'   => undef,
                    'pos'       => 0,
                    'msgstr'    => 'msgstr1',
                    'pos_doc'   => [0],
                    'previous'  => undef,
                    'type'      => undef
                }
            }
        }
    );
};

subtest 'read subroutine' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->read("t/t-po/context.po");
    is_deeply(
        $po->{po},
        {
            'id1' => {
                'context1' => {
                    'previous'  => undef,
                    'comment'   => undef,
                    'type'      => undef,
                    'automatic' => undef,
                    'msgstr'    => 'str1',
                    'pos'       => 0,
                    'pos_doc'   => [0]
                }
            }
        }
    );
};

subtest 'write subroutine' => sub {
    plan tests => 1;

    my $po       = Locale::Po4a::Po->new;
    my $expected = "t/t-po/context.expected.po";
    $po->read($expected);
    my $written = "t/tmp/t-po/context.written.po";
    $po->write($written);
    my $pid = open3( undef, my $stdout, my $stderr = gensym, "diff", $expected, $written );
    waitpid $pid, 0;
    my $success = !$?;

    unless ($success) {
        my $out = do { local $/; <$stdout> };
        my $err = do { local $/; <$stderr> };
        print <<DIFF;
------------------------------
stdout:
$out
------------------------------
stderr:
$err
------------------------------
DIFF
    }
    ok($success);
};

subtest 'gettext subroutine' => sub {
    plan tests => 2;

    my $po = Locale::Po4a::Po->new;
    $po->read("t/t-po/gettext.po");
    is( $po->gettext("id1"),                          "str1" );
    is( $po->gettext( "id1", msgctxt => "context2" ), "str2" );
};

subtest 'msgid subroutine' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw( msgid => "id1", msgstr => "str1" );
    is( $po->msgid(0), "id1" );
};

subtest 'msgid_doc subroutine' => sub {
    plan tests => 1;

    my $po = Locale::Po4a::Po->new;
    $po->push_raw( msgid => "id1", msgstr => "str1" );
    is( $po->msgid_doc(0), "id1" );
};

0;
