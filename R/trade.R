#' @title trade
#' @description Calculates MAgPIE trade or self-sufficiencies out of a gdx file
#'
#' @importFrom magclass where
#' @importFrom dplyr relocate
#' @export
#'
#' @param gdx GDX file
#' @param file a file name the output should be written to using write.magpie
#' @param level Level of regional aggregation ("reg", "glo", "regglo")
#' @param products Selection of products (either by naming products, e.g. "tece", or naming a set,e.g."kcr")
#' @param product_aggr aggregate over products or not (boolean)
#' @param attributes dry matter: Mt ("dm"), gross energy: PJ ("ge"), reactive nitrogen: Mt ("nr"), phosphor: Mt ("p"), potash: Mt ("k"), wet matter: Mt ("wm"). Can also be a vector.
#' @param weight in case relative=T also the weighting for the self sufficiencies is provided as it is an intensive parameter
#' @param relative if relative=TRUE, self sufficiencies are reported, so the amount of production divided by domestic demand
#' @param type exports-imports ("net-exports"), gross imports ("imports") or gross exports ("exports"); only valid if relative=FALSE
#' @details Trade definitions are equivalent to FAO CBS categories
#' @return trade (production-demand) as MAgPIE object; unit depends on attributes
#' @author Benjamin Leon Bodirsky, Florian Humpenoeder, Mishko Stevanovic
#' @examples
#'
#'   \dontrun{
#'     x <- trade(gdx="fulldata.gdx", level="regglo", products="kcr")
#'   }
#'

trade <- function(gdx, file = NULL, level = "reg", products = "k_trade",
                  product_aggr = FALSE, attributes = "dm", weight = FALSE,
                  relative = FALSE, type = "net-exports") {

  productAggr <- product_aggr # nolint

  if (!all(products%in%readGDX(gdx,"kall"))) {

    products <- try(readGDX(gdx, products))

    if (is.null(products)){
      products <- readGDX(gdx, "kall")
      warning("The specified commodity set in products argument does not exit.
              Instead the full kall set is given to products argument.")
    }
  }

  amtTraded <- suppressWarnings((readGDX(gdx, "ov21_trade")))
    

  production <- production(gdx, level = level, products = products,
                           product_aggr = FALSE, attributes = attributes)

  demand <- dimSums(demand(gdx, level = level, products = products,
                           product_aggr = FALSE, attributes = attributes),
                    dim = 3.1)
  ## The messages below seem to get triggered by extremely low values in diff.
  ## Could be a rounding issue. Rounding to 7 digits should be safe because we deal in 10e6 values mostly.
  diff <- round(production(gdx, level = "glo") - dimSums(demand(gdx, level = "glo"),
                                                         dim = 3.1),
                digits = 7)
  balanceflow <- readGDX(gdx, "f21_trade_balanceflow", react = "silent")

  if(is.null(balanceflow)) {
    balanceflow <- readGDX(gdx, "fm_trade_balanceflow", react = "silent")
    ## Needs to be converted to interface for timber module WIP
  }

  balanceflow <- balanceflow[,getYears(diff),]
  diff <- diff[,,getNames(balanceflow)] - balanceflow

  if(any(round(diff,2)>0)) {
    message("\nFor the following categories, overproduction is noticed (on top of balanceflow): \n",
            paste(unique(as.vector(where(round(diff, 2) > 0)$true$individual[, 3])), collapse = ", "), "\n")
  }
  if(any(round(diff,2)<0)) {
    warning("For the following categories, underproduction (on top of balanceflow): \n",
            paste(unique(as.vector(where(round(diff, 2) < 0)$true$individual[, 3])), collapse = ", "), "\n")
  }
  proddem <- mbind(
    add_dimension(production, dim = 3.1, add = "type", nm = "production"),
    add_dimension(demand, dim = 3.1, add = "type", nm = "demand")
  )
  if (relative) {
    if (productAggr){
      proddem <- dimSums(proddem, dim = "kall")
    }
    if (weight) {
      x = dimSums(proddem[, , "production"],
                              dim = 3.1) / round(dimSums(proddem[, , "demand"],
                                                   dim = 3.1), 8)
      weight = dimSums(proddem[, , "demand"],
                                   dim = 3.1) + 1e-8
      x[is.na(x)] <- 0
      x[is.infinite(x)] <- 0
      out <- list(x = x, weight = weight) 
                
    } else {
      out <- dimSums(proddem[,,"production"], dim = 3.1) / round(dimSums(proddem[, , "demand"],
                                                                   dim = 3.1), 8)
      out[is.na(out)] <- 0
      out[is.infinite(out)] <- 0

    }
  } else {

    if (is.null(amtTraded)) {

      out <- dimSums(proddem[, , "production"],
                     dim = 3.1) - dimSums(proddem[,,"demand"], dim = 3.1)

      if (type == "net-exports"){
        if (productAggr){
          out <- dimSums(out, dim="kall")
        }
      } else if (type == "exports") {
        out[out < 0] <- 0
        #replace global which is prod-dem which will always be ~0 with sum of imports
        if (level %in% c("glo", "regglo")){
          out["GLO",,] <- dimSums(out["GLO", , invert = TRUE], dim = 1)
        }
        if (productAggr){
          out <- dimSums(out, dim = "kall")
        }
      } else if (type == "imports") {
        out[out > 0] <- 0
        out <- -1 * out
        if (level %in% c("glo", "regglo")){
          out["GLO",,] <- dimSums(out["GLO", , invert = TRUE], dim = 1)
        }
        if (productAggr){
          out<-dimSums(out,dim="kall")
        }
      } else {stop("unknown type")}
 
    } else {

      im <- dimSums(amtTraded, dim = "i_ex")[, , "level", drop = TRUE] 
  
      #swtich dims around
      im <- as.data.frame(im, rev = 2) 
      im <- dplyr::relocate(im, "i_im",  .before = 1) 
      im <- as.magpie(im, spatial = 1, temporal = 2, tidy = TRUE)

      ex <- dimSums(amtTraded, dim = "i_im")[, , "level", drop = TRUE]

      diff <- production["GLO",,invert = TRUE] - demand["GLO",,invert=TRUE] + im - ex

      if (type == "net-exports"){
        out <- ex - im
        if (level %in% c("glo", "regglo")) {
          outG <- round(production(gdx, level = "glo") - dimSums(demand(gdx, level = "glo"),
                                                                 dim = 3.1),
                        digits = 7)[, , getItems(out, dim = 3)]
          getItems(outG, dim = 1) <- "GLO"
          out <- mbind(out, outG)
        }

      } else if (type == "imports") {
        out <- im
        if (level %in% c("glo", "regglo")) {
          outG <- dimSums(out, dim = 1)
          getItems(outG, dim = 1) <- "GLO"
          out <- mbind(out, outG)
        }
      } else if (type == "exports") {
        out <- ex
        outG <- dimSums(out, dim = 1)
        getItems(outG, dim = 1) <- "GLO"
        out <- mbind(out, outG)
      }
    }
    if (weight) {
      out <- list(x = out, weight = NULL)
    } else {
      out <- out
    }
  }

  if (is.list(out)) {
    return(out)
  } else {
    out(out, file)
  }
}
