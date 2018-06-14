if Rails.env == "development"
  GIT_BRANCH = `git status | sed -n 1p`.split(" ").last
  GIT_COMMIT = `git log | sed -n 1p`.split(" ").last
else
  GIT_BRANCH = ''
  GIT_COMMIT = ''
end
