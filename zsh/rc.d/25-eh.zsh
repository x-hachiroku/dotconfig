function garchive() {
    ls | parallel --jobs 1 -q zip -0 --junk-paths --test -r -m {}.cbz {}
}

alias hcheck='mkdir -p completed && find . -mindepth 2 -maxdepth 2 -name "galleryinfo.txt" -exec dirname {} \; | parallel --jobs 1 mv {} completed'

function lsgid() {
    perl -e 'my @gids=(); foreach my $g (split("\n", `find .`)) {if ($g=~/\[(\d+)\](.cbz)?$/) {push @gids, $1}} print join(",", @gids);'
}
