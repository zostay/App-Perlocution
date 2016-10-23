use v6;

use Template::Anti;

class MyApp::Templates {
    method main($dom, $_) is anti-template(:source<main.html>) {
        $dom('title,h1')».content(.<title>);
        $dom('p')».content(.<body>);
    }
}
