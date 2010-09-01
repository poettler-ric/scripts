#! /usr/bin sed -f

s/<?=[ ]*/<? echo /g
s/<?[ ]*/<?php /g
