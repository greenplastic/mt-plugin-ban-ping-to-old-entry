# Movable Type plugin for filtering trackback ping to old entry.
#
# Author:  yosshi <yosshi at gmail.com>
#

package MT::Plugin::BanPing2OldEntry;
use strict;
use MT;
use MT::Trackback;
use MT::Entry;
use MT::Util qw(offset_time_list);
use MT::JunkFilter qw(ABSTAIN);

use base 'MT::Plugin';

use constant JUNK => 1;
use constant MODERATE => 2;

my $plugin = MT::Plugin::BanPing2OldEntry->new({
  name => 'BanPing2OldEntry',
  description => 'filtering trackback ping to old entry',
  doc_link => 'http://fake.greenplastic.net/2005/10/banping2oldentry_plugin.php',
  version => '1.2',
  config_template => \&template,
  settings => new MT::PluginSettings([
    ['oe_days', { Default => 30 }],
    ['oe_method', { Default => JUNK }],
  ]),
  author_name => 'yosshi',
  author_link => 'http://profile.typekey.com/yosshi/',
});

MT->add_plugin($plugin);
MT->register_junk_filter({
  name => $plugin->name,
  plugin => $plugin,
  code   => sub { $plugin->handler(@_) },
});

sub handler {
  my($plugin, $obj) = @_;
  return ABSTAIN unless UNIVERSAL::isa($obj, 'MT::TBPing');
  
  my $blog_id = $obj->blog_id;
  my $config = $plugin->get_config_hash("blog:$blog_id");
  my $days = $config->{oe_days} || 30;
  my $method = $config->{oe_method} || JUNK;
  
  my @ago = offset_time_list(time - 3600 * 24 * $days, $blog_id);
  my $ago = sprintf "%04d%02d%02d%02d%02d%02d", $ago[5]+1900, $ago[4]+1, @ago[3,2,1,0];
  
  my $trackback = MT::Trackback->load($obj->tb_id);
  return ABSTAIN unless $trackback->entry_id;
  my $entry = MT::Entry->load($trackback->entry_id);
  
  if ($ago > $entry->created_on) {
    if ($method == JUNK) {
      return (-1, "trackback ping to old entry");
    } elsif ($method == MODERATE) {
      $obj->moderate;
      return (0, "Moderated trackback ping to old entry");
    }
  }
  return ABSTAIN;
}

sub template {
  return <<'EOT';
<p>filtering trackback ping to old entry</p>
<div class="setting">
<div class="label"><label>Older than:</label></div>
<div class="field">
<p><input type="text" size="2" name="oe_days" value="<TMPL_VAR NAME=OE_DAYS>" /> days</p>
</div>
<div class="label"><label>Junk or Moderate:</label></div>
<div class="field">
<input type="radio" name="oe_method" value="1"<TMPL_IF NAME=OE_METHOD_1> checked="checked"</TMPL_IF> /> Junk
<input type="radio" name="oe_method" value="2"<TMPL_IF NAME=OE_METHOD_2> checked="checked"</TMPL_IF> /> Moderate
</div>
</div>
EOT
}

1;
