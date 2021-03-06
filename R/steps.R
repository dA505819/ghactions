# script ====

#' Create a step to run [utils::Rscript]
#'
#' @inheritParams step
#'
#' @inheritParams utils::Rscript
#'
#' @inheritDotParams step -run
#'
#' @family steps
#' @family script
#'
#' @export
rscript <- function(options = NULL,
                    expr = NULL,
                    file = NULL,
                    args = NULL,
                    ...) {
  # input validation ====
  checkmate::assert_character(
    x = options,
    pattern = "^[--]",  # options must always start with -- as per RScript docs
    any.missing = FALSE,
    null.ok = TRUE
  )
  if (is.null(file)) {
    checkmate::assert_character(x = expr, any.missing = FALSE, null.ok = TRUE)
  } else {
    checkmate::assert_null(x = expr)  # there can only be expr OR file
    checkmate::assert_file_exists(
      x = file,
      extension = c("r", "R")
    )
  }
  checkmate::assert_character(
    x = args,
    any.missing = FALSE,
    null.ok = TRUE
  )

  # create run
  if (is.null(expr)) {
    run <- glue::glue_collapse(x = c("Rscript", options, file, args), sep = " ")
  } else {
    run <- purrr::map_chr(.x = expr, .f = function(x) {
      glue::glue_collapse(
        x = c(
          "Rscript",
          options,
          glue::glue("-e \"{x}\"")
        ),
        sep = " ")
    })
  }

  # create step ====
  step(
    run = run,
    ...
  )
}


# static deployment ====

#' Create an (action) step to deploy static assets
#'
#' @param src `[character(1)]`
#' giving the path relative from your `/github/workspace` to the directory to be published **without trailing slash**.
#' Defaults to `"$DEPLOY_PATH"`, an environment variable containing the path set by [website()].
#'
#' @param name `[character(1)]`
#' giving addtional options for the step.
#' Multiline strings are not supported.
#' Defaults to a name for the deploy step.
#'
#' @param if `[character(1)]`
#' giving additional options for the step.
#' Multiline strings are not supported.
#' Defaults to `"github.ref == 'refs/heads/master'"` to only deploy from branch `master`.
#'
#' @inheritParams step
#'
#' @inheritDotParams step -run -uses -name -env -with -shell
#'
#' @family steps
#' @family actions
#' @family static deployment
#'
#' @name deploy_static
NULL

#' @describeIn deploy_static Wraps the external [ghpages action](https://github.com/maxheld83/ghpages/) to deploy to [GitHub Pages](https://pages.github.com).
#'
#' @section GitHub Pages:
#' **Remember to provide a GitHub personal access token secret named `GH_PAT` to the GitHub UI.**
#' 1. Set up a new PAT.
#'    You can use [usethis::browse_github_pat()] to get to the right page.
#'    Remember that this PAT is *not* for your local machine, but for GitHub actions.
#' 2. Copy the PAT to your clipboard.
#' 3. Go to the settings of your repository, and paste the PAT as a secret.
#'    The secret must be called `GH_PAT`.
#'
#' @export
ghpages <- function(src = "$DEPLOY_PATH",
                    name = "Deploy to GitHub Pages",
                    `if` = "github.ref == 'refs/heads/master'",
                    ...) {
  checkmate::assert_string(x = src, na.ok = FALSE, null.ok = FALSE)

  step(
    name = name,
    `if` = `if`,
    uses = "maxheld83/ghpages@v0.2.0",
    env = list(
      BUILD_DIR = src,
      GH_PAT = "${{ secrets.GH_PAT }}"
    ),
    ...
  )
}

#' @describeIn deploy_static Wraps the external [rsync action](https://github.com/maxheld83/rsync/) to deploy via [Rsync](https://rsync.samba.org) over SSH.
#'
#' @param HOST_NAME `[character(1)]`
#' giving the name of the server you wish to deploy to, such as `foo.example.com`.
#'
#' @param HOST_IP `[character(1)]`
#' giving the IP of the server you wish to deploy to, such as `111.111.11.111`.
#'
#' @param HOST_FINGERPRINT `[character(1)]`
#' giving the fingerprint of the server you wish to deploy to, can have different formats.
#'
#' @param user `[character(1)]`
#' giving the user at the target `HOST_NAME`.
#'
#' @param dest `[character(1)]`
#' giving the directory from the root of the `HOST_NAME` target to write to.
#'
#' @section RSync:
#' **Remember to provide `SSH_PRIVATE_KEY` and `SSH_PUBLIC_KEY` as secrets to the GitHub UI.**.
#'
#' @export
rsync <- function(src = "$DEPLOY_PATH",
                  name = "Deploy via RSync",
                  `if` = "github.ref == 'refs/heads/master'",
                  HOST_NAME,
                  HOST_IP,
                  HOST_FINGERPRINT,
                  user,
                  dest,
                  env = NULL,
                  with = NULL,
                  ...) {
  # input validation
  purrr::map(
    .x = list(HOST_NAME, HOST_IP, HOST_FINGERPRINT, src, user, dest),
    .f = checkmate::assert_string,
    na.ok = FALSE,
    null.ok = FALSE
  )

  args <- glue::glue(
    "$GITHUB_WORKSPACE/{src}/",  # source
    "{user}@{HOST_NAME}:{dest}",  # target and destination
    .sep = " "
  )

  step(
    uses = "maxheld83/rsync@v0.1.1",
    `if` = `if`,
    env = c(
      env,
      list(
        HOST_NAME = HOST_NAME,
        HOST_IP = HOST_IP,
        HOST_FINGERPRINT = HOST_FINGERPRINT,
        SSH_PRIVATE_KEY = "${{ secrets.SSH_PRIVATE_KEY }}",
        SSH_PUBLIC_KEY = "${{ secrets.SSH_PUBLIC_KEY }}"
      )
    ),
    with = c(
      with,
      list(args = args)
    ),
    ...
  )
}


rsync_fau <- function(src = "$DEPLOY_PATH",
                      dest = fs::path("/proj/websource/docs/FAU/fakultaet/phil/www.datascience.phil.fau.de/websource", gh::gh_tree_remote()$repo),
                      user = "pfs400wm",
                      ...) {
  rsync(
    HOST_NAME = "karli.rrze.uni-erlangen.de",
    HOST_IP = "131.188.16.138",
    HOST_FINGERPRINT = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFHJVSekYKuF5pMKyHe1jS9mUkXMWoqNQe0TTs2sY1OQj379e6eqVSqGZe+9dKWzL5MRFpIiySRKgvxuHhaPQU4=",
    user = user,
    src = src,
    dest = dest,
    name = "Deploy Website",
    ...
  )
}


#' @describeIn deploy_static Wraps the external [netlify cli action](https://github.com/netlify/actions) to deploy to [Netlify](https://www.netlify.com).
#'
#' @section Netlify:
#' **Remember to provide `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` (optional) as secrets to the GitHub UI.**
#'
#' @param prod `[logical(1)]`
#' giving whether the deploy should be to production.
#'
#' @param site `[character(1)]`
#' giving a site ID to deploy to.
#'
#' @export
netlify <- function(src = "$DEPLOY_PATH",
                    name = "Deploy to Netlify",
                    `if` = "github.ref == 'refs/heads/master'",
                    prod = TRUE,
                    with = NULL,
                    env = NULL,
                    site,
                    ...) {
  checkmate::assert_string(x = src, na.ok = FALSE, null.ok = FALSE)
  checkmate::assert_string(x = site, na.ok = FALSE, null.ok = FALSE)
  checkmate::assert_flag(x = prod, na.ok = FALSE, null.ok = FALSE)

  # prepare args
  args <- c(
    glue::glue('--dir {src}'),
    if (prod) "prod" else NULL,
    glue::glue('--site {site}')
  )

  step(
    name = name,
    `if` = `if`,
    uses = "netlify/actions/cli@645ae7398cf5b912a3fa1eb0b88618301aaa85d0",
    env = c(
      env,
      list(
        NETLIFY_AUTH_TOKEN = "${{ secrets.NETLIFY_AUTH_TOKEN }}",
        NETLIFY_SITE_ID = "${{ secrets.NETLIFY_SITE_ID }}"
      )
    ),
    with = c(
      with,
      list(args = args)
    ),
    ...
  )
}

#' @describeIn deploy_static Wraps the external [Google Firebase CLI action](https://github.com/w9jds/firebase-action) to deploy to [Google Firebase](http://firebase.google.com).
#'
#' @param PROJECT_ID `[character(1)]`
#' giving a specific project to use for all commands, not required if you specify a project in your `.firebaserc`` file.
#'
#' @section Google Firebase:
#' **Remember to provide `FIREBASE_TOKEN` as a secret to the GitHub UI.**
#'
#' Configuration details other than `PROJECT_ID` are read from the `firebase.json` at the root of your repository.
#'
#' Because firebase gets the deploy directory from a `firebase.json` file, it cannot use `$DEPLOY_DIR`.
#' Manually edit your `firebase.json` to provide the deploy path.
# tracked in https://github.com/maxheld83/ghactions/issues/80
#'
#' @export
firebase <- function(name = "Deploy to Firebase",
                     `if` = "github.ref == 'refs/heads/master'",
                     PROJECT_ID = NULL,
                     with = NULL,
                     env = NULL,
                     ...) {
  checkmate::assert_string(x = PROJECT_ID, null.ok = TRUE)

  step(
    name = name,
    `if` = `if`,
    uses = "w9jds/firebase-action@v1.0.1",
    env = c(
      env,
      list(
        FIREBASE_TOKEN = "${{ secrets.FIREBASE_TOKEN }}",
        PROJECT_ID = PROJECT_ID
      )
    ),
    with = c(
      with,
      list(args = "deploy --only hosting")
    ),
    ...
  )
}


# installation ====

#' Create a step to checkout a repository
#'
#' @family steps
#' @family installation
#'
#' @export
checkout <- function() {
  step(
    name = "Checkout Repository",
    uses = "actions/checkout@master"
  )
}

# this should always closely follow https://github.com/r-lib/r-azure-pipelines/blob/master/templates/pkg-install_dependencies.yml

#' Create a step to install R package dependencies
#'
#' Installs R package dependencies from a `DESCRIPTION` at the repository root.
#'
#' @inheritParams step
#' @param ... Passed to [rscript()]
#'
#' @inheritDotParams step -run -uses
#'
#' @family steps
#' @family installation
#'
#' @export
install_deps <- function(name = "Install Package Dependencies", ...) {
  rscript(
    name = name,
    expr = c(
      "install.packages('remotes', repos = 'https://demo.rstudiopm.com/all/__linux__/bionic/latest')",
      "remotes::install_deps(dependencies = TRUE, repos = 'https://demo.rstudiopm.com/all/__linux__/bionic/latest')"
    ),
    ...
  )
}


# pkg dev ====

# all of the below should closely follow https://github.com/r-lib/r-azure-pipelines

#' CI/CD steps for a package at the repository root
#'
#' @name pkg_dev
#'
#' @inheritParams step
#'
#' @family steps
#' @family pkg_development
NULL

#' @describeIn pkg_dev [rcmdcheck::rcmdcheck()]
rcmd_check <- function(name = "Check Package") {
  rscript(
    name = name,
    expr = "rcmdcheck::rcmdcheck(error_on = 'error', check_dir = 'check')"
  )
}

#' @describeIn pkg_dev [covr::codecov()]
covr <- function(name = "Run Code Coverage") {
  rscript(
    name = name,
    expr = "covr::codecov(quiet = FALSE, commit = '$GITHUB_SHA', branch = '$GITHUB_REF')"
  )
}

