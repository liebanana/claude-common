# merge-settings.jq — input: [baseline, repo] (via `jq -s`). Output: merged settings.
# Rules: repo wins on conflicting keys ($b * $r); permissions.allow/deny are unioned;
# each hooks.<Event> list = repo groups + baseline groups whose first command is absent.
.[0] as $b | .[1] as $r
| def union($x; $y): (($x // []) + ($y // [])) | unique;
  def cmds: [.hooks[]?.command];
  def merge_hooks($bh; $rh):
      ((($bh // {}) | keys) + (($rh // {}) | keys)) | unique
      | map(. as $k
            | ($rh[$k] // []) as $rg
            | ($rg | map(cmds) | add // []) as $have
            | { key: $k,
                value: ($rg + (($bh[$k] // []) | map(select((cmds | .[0]) as $c | ($have | index($c)) == null)))) })
      | from_entries;
  ($b * $r)
  | .permissions.allow = union($b.permissions.allow; $r.permissions.allow)
  | .permissions.deny  = union($b.permissions.deny;  $r.permissions.deny)
  | .hooks = merge_hooks($b.hooks; $r.hooks)
  | if .permissions.allow == [] then del(.permissions.allow) else . end
  | if .permissions.deny  == [] then del(.permissions.deny)  else . end
  | if .permissions == {} then del(.permissions) else . end
  | if .hooks == {} then del(.hooks) else . end
