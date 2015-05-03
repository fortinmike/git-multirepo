echo ">>> Setup a basic repo"
dir_name="PreCommitHookAddTest"
rm -rf $dir_name
mkdir $dir_name; cd $dir_name 
git init; git commit --allow-empty -m "Initial commit"

echo ">>> Add a pre-commit hook that stages a file"
echo "unset $(git rev-parse --local-env-vars); touch b; git add b" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo ">>> Try committing a new file using the '-o' flag"
touch c
git add c
git commit -o -m "Commit that ran the pre-commit hook and should contain file 'b'" -- c

echo ">>> Results (expected: working copy clean)"
git status --porcelain

echo ">>> Stage the file after the fact"
git add b

echo ">>> Notice how the working copy is now clean"
git status --porcelain
