#
# Copyright 2018 (c) Andrey Galkin
#


class cfsystem::defaults {
    include cfnetwork

    $service_face = $cfnetwork::service_face
}