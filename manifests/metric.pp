#
# Copyright 2018-2019 (c) Andrey Galkin
#

define cfsystem::metric (
    String[1]
        $type = $title,
    Hash
        $info = {},
) {
    if defined('cfmetrics') {
        ensure_resource("@cfmetrics::collector::${type}", $title, $info)
    }
}
