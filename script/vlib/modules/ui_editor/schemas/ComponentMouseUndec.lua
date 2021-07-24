return {
    {
        version = 122,
        fields = {
            {
                name = "undeciphered_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_2",
                field_type = "Hex",
                length = 16,
            },
            {
                name = "undeciphered_3",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_4",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_5",
                field_type = "StringU8",
            }
        },
    },
    {
        -- version = 122,
        fields = {
            {
                name = "undeciphered_1",
                field_type = "Hex",
                length = 4,
            },
            {
                name = "undeciphered_2",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_3",
                field_type = "StringU8",
            },
            {
                name = "undeciphered_4",
                field_type = "StringU8",
            }
        },
    }
}

-- TODO gotta do this! from Cpecific

-- idk what this actually does
-- TODO decipher this

-- $this->num_sth = my_unpack_one($this, 'l', fread($h, 4));
-- my_assert($this->num_sth < 20, $my);
-- for ($i = 0; $i < $this->num_sth; ++$i){
--     $a = array();
--     $a[] = tohex(fread($h, 4));
--     if ($v >= 122 && $v < 130){
--         $a[] = tohex(fread($h, 16));
--     }
--     $a[] = read_string($h, 1, $my);
--     $a[] = read_string($h, 1, $my);
--     $a[] = read_string($h, 1, $my);
--     $this->sth[] = $a;
-- }