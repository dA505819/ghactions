% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setup.R
\name{use_ghactions}
\alias{use_ghactions}
\title{Workflow automation with GitHub Actions}
\usage{
use_ghactions(workflow = website())
}
\arguments{
\item{workflow}{\verb{[list(list())]}
A named list as created by one of the \code{\link[=workflow]{workflow()}} functions.
Defaults to \code{\link[=website]{website()}}.}
}
\value{
A logical vector indicating if file was modified.
}
\description{
Sets up workflow automation, including continuous integration and deployment (CI/CD) for different kinds of R projects on GitHub actions.
This function
\itemize{
\item transforms a list into the GitHub actions syntax,
\item writes it out to \verb{.github/workflows/} in your repository.
}
}
\examples{
\dontrun{
use_ghactions(workflow = website())
}
}
\seealso{
Other setup: 
\code{\link{edit_workflow}()},
\code{\link{use_ghactions_badge}()}
}
\concept{setup}
