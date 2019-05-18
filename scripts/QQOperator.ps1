function ??
{
    [cmdletbinding()]
    param(
        [bool]$condition,
        $IfTrue,
        $IfFalse
    )
    if($condition)
    {
        $IfTrue
    }
    else
    {
        $IfFalse
    }
}

$foo = 124

$val = ?? ($foo -eq 123) 'yes' 'no'