<%args>
$widget
$field
$param
$oc_id => undef
$story_id => undef
$media_id => undef
$instant  => 0
</%args>
<%once>;
my $fs = PREVIEW_LOCAL ? Bric::Util::Trans::FS->new : undef;
my $send_msg = sub { $m->comp('/lib/util/status_msg.mc', @_) };
my $comp_root = $m->interp->comp_root->[0][1];
</%once>

<%init>;
# Hunt the wumpus
$field = 'publish' if $field eq "$widget|publish_cb";
return unless $field eq 'preview' or $field eq "publish";

# Grab the story and media IDs from the session.
my ($story_pub_ids, $media_pub_ids, $story_pub, $media_pub);
if (my $d = get_state_data($widget)) {
    ($story_pub_ids, $media_pub_ids, $story_pub, $media_pub) =
      @{$d}{qw(story media story_pub media_pub)};
    clear_state($widget);
} elsif (! defined $story_id && ! defined $media_id ) { return }

if ($field eq 'preview') {
    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => PREVIEW_ROOT });
    if (defined $media_id) {
        my $media = get_state_data('media_prof', 'media');
        unless ($media && (defined $media_id) && ($media->get_id == $media_id)) {
            $media = Bric::Biz::Asset::Business::Media->lookup
              ({ id => $media_id,
                 checkout => $param->{checkout} });
        }

        # Move out the story and then redirect to preview.
        my $url = $b->preview($media, 'media', get_user_id(), $m, $oc_id);
        &$send_msg("Redirecting to preview.");
        redirect_onload($url);
    } else {
        my $s = get_state_data('story_prof', 'story');
        unless ($s && defined $story_id && $s->get_id == $story_id) {
            $s = Bric::Biz::Asset::Business::Story->lookup
              ({ id => $story_id,
                 checkout => $param->{checkout} });
        }

        # Get all the related media to be previewed as well
        foreach my $r ($s->get_related_objects) {
            next if (ref $r eq 'Bric::Biz::Asset::Business::Story');

            # Make sure this media object isn't checked out.
            if ($r->get_checked_out) {
                add_msg($lang->maketext('Cannot auto-publish related media [_1] because it is checked out','&quot;'.$r->get_title.'&quot'));
                next;
            }
            $b->preview($r, 'media', get_user_id(), $m, $oc_id);
        }
        # Move out the story and then redirect to preview.
        my $url = $b->preview($s, 'story', get_user_id(), $m, $oc_id);
        &$send_msg("Redirecting to preview.");
        redirect_onload($url);
    }
} else {
    # Instantiate the Burner object.
    my $b = Bric::Util::Burner->new({ out_dir => STAGE_ROOT });
    my $stories = mk_aref($story_pub_ids);
    my $media = mk_aref($media_pub_ids);

    # Iterate through each story and media object to be published.
    my $count = @$stories;
    foreach my $sid (@$stories) {
        # Instantiate the story.
        my $s = $story_pub->{$sid} ||
          Bric::Biz::Asset::Business::Story->lookup({ id => $sid });
        $b->publish($s, 'story', get_user_id(), $param->{pub_date});
        add_msg($lang�>maketext("Story [_1] published.","&quot;" . $s->get_title . "&quot;"))
          if $count <= 3;
    }
    add_msg($lang->maketext("[_1] stories published."),$count) if $count > 3;

    $count = @$media;
    foreach my $mid (@$media) {
        # Instantiate the media.
        my $m = $media_pub->{$mid} ||
          Bric::Biz::Asset::Business::Media->lookup({ id => $mid });
        $b->publish($m, 'media', get_user_id(), $param->{pub_date});
        add_msg($lang�>maketext("Media [_1] published.","&quot;" . $m->get_title . "&quot;"))
          if $count <= 3;
    }
    add_msg($lang->maketext("[_1] media published."),$count) if $count > 3;

    redirect_onload(last_page()) unless $instant;
}
</%init>
