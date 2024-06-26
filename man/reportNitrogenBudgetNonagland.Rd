% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/reportNitrogenBudgetNonagland.R
\name{reportNitrogenBudgetNonagland}
\alias{reportNitrogenBudgetNonagland}
\title{reportNitrogenBudgetNonagland}
\usage{
reportNitrogenBudgetNonagland(gdx, grid = FALSE, dir = ".")
}
\arguments{
\item{gdx}{GDX file}

\item{grid}{if TRUE, disaggregate to grid level}

\item{dir}{for gridded outputs: magpie output directory which contains a mapping file (rds) for disaggregation}
}
\description{
Reports the Nitrogen Budgets of non-agricultural lands for future MAgPIE projections
}
\examples{
  \dontrun{
    x <- reportNitrogenBudgetNonagland(gdx)
  }

}
\seealso{
\code{\link{NitrogenBudget}}
}
\author{
Benjamin Leon Bodirsky
}
