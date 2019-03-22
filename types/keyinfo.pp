#
# Copyright 2017-2019 (c) Andrey Galkin
#

type Cfsystem::Keyinfo = Struct[{
    'type'    => Cfsystem::Keytype,
    'bits'    => Cfsystem::Rsabits,
    'private' => String[1],
    'public'  => String[1],
}]
