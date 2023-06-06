package Tk::YADialog;

=head1 NAME

Tk::YADialog - Yet another dialog

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Tk;
use base qw(Tk::Derived Tk::Toplevel);
Construct Tk::Widget 'YADialog';

=head1 SYNOPSIS

 require Tk::YADialog;
 my $dialog = $window->YADialog(
	-buttons => ['Ok, 'Close'],
 );
 my $e = $dialog->Entry->pack;
 my $but = $dial->Show;
 if ($but eq 'Ok') {
	$color = $e->Get;
 }

=head1 DESCRIPTION

Provides a basic dialog. Less noisy than Tk::Dialog.
Inherits L<Tk::Toplevel>.


=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-buttons>

Default value ['Close'].

=item Switch: B<-command>

Callback, is called when a button is pressed.

=item Switch: B<-defaultbutton>

Default value not defined.

=item Switch: B<-padding>

Horizontal and vertical padding for the buttons.
Default value 20.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	my $buttons = delete $args->{'-buttons'};
	$buttons = ['Close'] unless defined $buttons;
	my $padding = delete $args->{'-padding'};
	$padding = 20 unless defined $padding;

	$self->{DEFAULTBUTTON} = delete $args->{'-defaultbutton'};

	$self->SUPER::Populate($args);
	
	$self->{PADDING} = $padding;
	$self->{PRESSED} = '';
	
	$self->protocol('WM_DELETE_WINDOW', sub { $self->CancelDialog });
	$self->bind('<Escape>' => sub { $self->CancelDialog });

	my @pad = (-padx => $padding, -pady => $padding);
	my $bframe = $self->Frame->pack(-side => 'bottom', -fill => 'x');
	$self->Advertise('buttonframe', $bframe);
	
	for (reverse @$buttons) {
		my $but = $_;
		if ($but =~ /^ARRAY/) {
			my $b =$bframe->Button(
				-text => $but->[0],
				-command => $$but->[1],
			)->pack(-side => 'right', -padx => $padding, -pady => $padding);
			$self->Advertise($but->[0], $b);
		} else {
			my $b = $bframe->Button(
				-text => $but,
				-command => sub { $self->Pressed($but) },
			)->pack(-side => 'right', -padx => $padding, -pady => $padding);
			$self->Advertise($but, $b);
		}
		my $lab = pop @$buttons;
	}
	$self->transient($self->Parent->toplevel);
	$self->withdraw;
	$self->ConfigSpecs(
		-command => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => ['SELF'],
	);

}

=head1 METHODS

=over 4

=cut

sub ButtonPack {
	my ($self, $but) = @_;
	my $pad = $self->{PADDING};
	$but->pack(
		-side => 'right',
		-padx => $pad,
		-pady => $pad,
	);
}

sub CancelDialog {
	$_[0]->Pressed('*Cancel*');
}

=item Switch: B<Get>

Returns the button that was pressed.

=cut

sub Get { return $_[0]->{PRESSED} }

sub Pressed {
	my $self = shift;
	if (@_) {
		$self->{PRESSED} = shift;
		$self->withdraw;
	}
	return $self->{PRESSED}
}

=item Switch: B<Show>

Pops up the dialog.

=cut

sub Show {
	my $self = shift;
	my ($grab) = @_;
	my $old_focus = $self->focusSave;
	my $old_grab = $self->grabSave;

	shift if defined $grab && length $grab && ($grab =~ /global/);
	$self->Popup(@_);

	Tk::catch {
		if (defined $grab && length $grab && ($grab =~ /global/)) {
			$self->grabGlobal;
		} else {
			$self->grab;
		}
	};
	if (my $focusw = $self->cget(-focus)) {
		$focusw->focus;
	} elsif (defined $self->{DEFAULTBUTTON}) {
		$self->Subwidget($self->{DEFAULTBUTTON})->focus;
	} else {
		$self->focus;
	}
	$self->Wait;
	&$old_focus;
	&$old_grab;
	return $self->{PRESSED};
}

sub Wait {
	my $self = shift;
	$self->Callback(-showcommand => $self);
	$self->waitVariable(\$self->{PRESSED});
	$self->grabRelease if Tk::Exists($self);
	$self->withdraw if Tk::Exists($self);
	$self->Callback(-command => $self->{PRESSED});
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;
