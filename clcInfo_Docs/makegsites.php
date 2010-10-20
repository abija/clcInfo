<?php
$sdir = "G:\\clcInfo_Docs\\gsites\\";
$odir = "G:\\clcInfo_Docs\\gsitesinline\\";
// transform the css file
$f = file_get_contents($sdir."css.css");
$f = str_replace(".", "class=\"", $f);
$f = str_replace(" { ", "\"\r\nstyle=\"", $f);
$f = str_replace(" }", "\"", $f);
file_put_contents($sdir."css.inline.txt", $f);
print("parsed css file\n");

// read it into an array to be used for replacements
$inline_styles = file($sdir."css.inline.txt");
$num_inline_styles = floor(count($inline_styles)/2);
print("read inline styles, found ".$num_inline_styles." entries\n");

foreach (glob($sdir."*.html") as $filename) {
	$f = file_get_contents($filename);
	$f = str_replace("<link href=\"css.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n", "", $f);
	for ($i = 0; $i < $num_inline_styles; $i++) {
		$f = str_replace(trim($inline_styles[$i * 2]), trim($inline_styles[$i * 2 + 1]), $f);
	}
	$fn = $odir.basename($filename);
	file_put_contents($fn, $f);
	print("completed ".$fn."\n");
}
?>
