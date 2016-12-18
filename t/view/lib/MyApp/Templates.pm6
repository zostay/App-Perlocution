use v6;

use Template::Anti;

class MyApp::Templates {
    method main($dom, :$title, :$body) is anti-template(:source<main.html>) {
        $dom('title,h1')».content($title);
        $dom('p')».content($body);
    }

    method list($dom, *%item) is anti-template(:source<list.html>) {
        $dom('tbody tr', :one).duplicate(%item.list.sort, -> $tr, $_ {
            $tr('.key', :one).content(.key);
            $tr('.value', :one).content(.value);
        });
    }
}
