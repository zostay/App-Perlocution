use v6;

use Template::Anti;

BEGIN note "HERE";

class MyApp::Templates {
    method from-plan(::?CLASS:U: :$context) { }

    method main($dom, $_) is anti-template('main.html') {
        note "main 1";
        $dom('title,h1')».content(.<title>);
        $dom('p')».content(.<body>);
    }
}
