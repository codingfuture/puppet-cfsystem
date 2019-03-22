#
# Copyright 2017-2019 (c) Andrey Galkin
#


type Cfsystem::Keygenopts = Struct[{
    'type' => Cfsystem::Keytype,
    'bits' => Cfsystem::Rsabits,
}]
