release-patch:
    #!/usr/bin/env bash
    set -e
    git pull origin master
    git push origin master

    for i in lib/*; do
        if [ -d "$i" ]; then
            cd $i
            ion bump patch --no-commit
            git add Project.toml
            cd ../..
        fi
    done
    ion bump patch --no-commit
    git add Project.toml

    git diff --quiet && git diff --staged --quiet || git commit -m "Bump patch version"
    git push origin master

    for i in lib/*; do
        if [ -d "$i" ]; then
            ion summon $i --skip-note
        fi
    done
    ion summon
