echo "----> Setup a new test repo"
dir_name="PreCommitHookAddTest"
rm -rf $dir_name; mkdir $dir_name; cd $dir_name
git init; git commit --allow-empty -m "Initial commit"

echo "----> Add a pre-commit hook that stages a file that doesn't currently exist in the repo"
echo "touch auto-added; git add auto-added" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "----> Try committing a new file using the '-o' flag"
touch manually-added; git add manually-added
git commit -o -m "Commit that ran the pre-commit hook and should contain file 'auto-added'" -- manually-added

echo "----> Results (expected: working copy clean; actual: auto-added is reported as both DELETED and UNTRACKED. HEAD and working copy are the same, staging area contains ‘incorrect' state)"
git status

echo "----> Stage the file after the fact"
git add auto-added

echo "----> Notice that the working copy is now clean"
git status