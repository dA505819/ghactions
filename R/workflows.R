use_ghactions <- function(workflow = website$rmarkdown$fau()) {
  # input validation
  # TODO infer project kind

  # check for github
  usethis:::check_uses_github()

  # make project-specific action blocks with leading workflow block
  res <- make_workflow(l = workflow)

  # write out to disc
  # this is modelled on use_template, but because we already have the full string in above res, we don't need to go through whisker/mustache again
  usethis::use_directory(path = ".github", ignore = TRUE)

  # TODO not sure its kosher to use this function; it's exported but marked as internal
  new <- usethis::write_over(
    path = ".github/main.workflow",
    lines = res,
    quiet = TRUE
  )

  usethis::ui_done(x = "GitHub actions is set up and ready to go.")
  usethis::ui_todo(x = "Commit and push the changes.")
  # TODO maybe automatically open webpage via browse_ghactions here
  usethis::ui_todo(x = "Visit the actions tab of your repository on github.com to check the results.")

  # return true/false for changed files as in original use_template
  invisible(new)
}

make_workflow <- function(l,
                          IDENTIFIER = "Build and deploy",
                          on = "push",
                          resolves = names(l)[length(l)]) {
  res <- make_workflow_block(
    IDENTIFIER = IDENTIFIER,
    on = on,
    resolves = resolves
  )
  res <- c(res, list2action_blocks(l))
  res <- glue::as_glue(res)
  res
}

list2action_blocks <- function(l) {
  res <- purrr::imap_chr(
    .x = l,
    .f = function(x, y) {
      rlang::exec(.fn = make_action_block, !!!c(IDENTIFIER = y, x))
    }
  )
  # this makes it easier to read in debugging; above imap kills s3 attributes
  res <- glue::as_glue(x = res)
  res
}

# Objects: workflow blocks ===
website <- NULL
website$rmarkdown <- NULL
website$rmarkdown$fau <- function(reponame = NULL) {
  if (is.null(reponame)) {
    reponame <- usethis:::github_repo()
  }
  list(
    `Build image` = list(
      uses = "actions/docker/cli@c08a5fc9e0286844156fefff2c141072048141f6",
      args = "build --tag=repo:latest ."
    ),
    `Render RMarkdown` = list(
      uses = "maxheld83/ghactions/Rscript-byod@master",
      needs = "Build image",
      args = "-e 'rmarkdown::render_site()'"
    ),
    `Deploy with rsync` = list(
      uses = "maxheld83/rsync@v0.1.1",
      needs = "Render RMarkdown",
      secrets = c("SSH_PRIVATE_KEY", "SSH_PUBLIC_KEY"),
      env = list(
        HOST_NAME = "karli.rrze.uni-erlangen.de",
        HOST_IP = "131.188.16.138",
        HOST_FINGERPRINT = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFHJVSekYKuF5pMKyHe1jS9mUkXMWoqNQe0TTs2sY1OQj379e6eqVSqGZe+9dKWzL5MRFpIiySRKgvxuHhaPQU4="
      ),
      args = c(
        "$GITHUB_WORKSPACE/_site/",
        fs::path("pfs400wm@$HOST_NAME:/proj/websource/docs/FAU/fakultaet/phil/www.datascience.phil.fau.de/websource", reponame)
      )
    )
  )
}