#
# Copyright 2017 (c) Andrey Galkin
#

type Cfsystem::Keyinfo = Struct[{
    'type'    => Cfsystem::Keytype,
    'bits'    => Cfsystem::Rsabits,
    'private' => String[1],
    'public'  => String[1],
}]
