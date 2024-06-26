% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/NitrogenBudgetWithdrawals.R
\name{NitrogenBudgetWithdrawals}
\alias{NitrogenBudgetWithdrawals}
\title{NitrogenBudgetWithdrawals}
\usage{
NitrogenBudgetWithdrawals(
  gdx,
  kcr = "sum",
  net = TRUE,
  level = "reg",
  dir = "."
)
}
\arguments{
\item{gdx}{GDX file}

\item{kcr}{"sum" provides the totals over all crops, "kcr" provides outputs by kcr}

\item{net}{TRUE only provides total net-withdrawals, otherwise all categories are
returned (fixation and seed are returned positive, not negative)}

\item{level}{aggregation level, reg, glo or regglo, cell, grid or iso}

\item{dir}{for gridded outputs: magpie output directory which contains a mapping file (rds) for disaggregation}
}
\description{
calculates projections of Nitrogen Budgets withdrawals for Croplands from a MAgPIE gdx file
}
\examples{
\dontrun{
x <- NitrogenBudgetWithdrawals(gdx)
}

}
\author{
Benjamin Leon Bodirsky, Michael Crawford
}
