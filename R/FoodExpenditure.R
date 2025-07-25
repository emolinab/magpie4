#' @title FoodExpenditure
#' @description Calculates the food expenditure in USD per year
#'
#' @export
#'
#' @param gdx GDX file
#' @param level spatial aggregation. can be "iso","reg","regglo","glo"
#' @param after_shock FALSE is using the exogenous real income and the prices before a shock, TRUE is using the endogeenous real income that takes into account food price change on real income, "after_price_before_demand" takes into account price changes on real income, but assumes no demand adjustment
#' @param products selected products or sets of products
#' @param product_aggr if true, aggregation over products
#' @param per_capita per capita or total population
#' @param valueAdded whether to add the value-added 
#' marketing margin to the total expenditures
#'
#' @return magpie object with per capita consumption
#' @author Benjamin Leon Bodirsky
#' @importFrom magclass colSums mbind add_columns dimSums getNames
#' @importFrom magpiesets findset
#' @importFrom GDPuc convertGDP
#' @examples
#'
#'   \dontrun{
#'     x <- FoodExpenditure(gdx)
#'   }
#'

FoodExpenditure<-function(gdx, level="reg", after_shock=TRUE, products="kfo",
                          product_aggr=TRUE, per_capita=TRUE, valueAdded = FALSE ){ #nolint


  if (valueAdded) {
    avExp <- suppressWarnings(readGDX(gdx, "p15_value_added_expenditures_pc"))
    popiso <- population(gdx, level = "iso")

    if(is.null(avExp)) {
       # make backwards compatible with input values in the mapping folder for now
       markupCoef <- read.csv(system.file("extdata", "Markup_coef.csv", package = "magpie4"))
       colnames(markupCoef) <- NULL
       colnames(markupCoef) <- markupCoef[1,] 
       markupCoef <- markupCoef[2:nrow(markupCoef), c(1:5)]
       markupCoef <- tidyr::pivot_longer(markupCoef, cols = c("a", "b", "c"), names_to = "coef", values_to = "value")
       markupCoef$value <- as.double(markupCoef$value)
       markupCoef <- as.magpie(markupCoef, spatial = "GLO", temporal = "y2010", tidy = TRUE)
       gdp <- readGDX(gdx, "im_gdp_pc_mer_iso")
       attr <- readGDX(gdx, "fm_attributes")
       nutrAttr <- readGDX(gdx, "fm_nutrition_attributes")
       kcalPcIso <- readGDX(gdx, "p15_kcal_pc_iso")

    
        marginFAH = markupCoef[,,"fah"][,,"a"] * markupCoef[,,"fah"][,, "b"]^log(gdp) +
                    markupCoef[,,"fah"][,, "c"] * attr[,,"wm"][,,getItems(markupCoef, dim = 3.1)] 
        marginFAH = collapseNames(marginFAH / (nutrAttr[,getYears(marginFAH),getItems(markupCoef, dim = 3.1)][,,"kcal"] * 10^6))
        
     marginFAFH = (markupCoef[,,"fafh"][,,"a"] * markupCoef[,,"fafh"][,, "b"]^log(gdp) +
                  markupCoef[,,"fafh"][,, "c"]) * attr[,,"wm"][,,getItems(markupCoef, dim = 3.1)]
     marginFAFH = collapseNames(marginFAFH / (nutrAttr[,getYears(marginFAFH),getItems(markupCoef, dim = 3.1)][,,"kcal"]*10^6))
    
    fafhCoef <- read.csv(system.file("extdata", "Fafh_coef.csv", package = "magpie4"))
    colnames(fafhCoef) <- NULL
    fafhCoef <- as.magpie(fafhCoef[,c(1,2) ], temporal = "y2010", spatial = NULL, tidy= TRUE)
    fafhShr = fafhCoef[,,"a_fafh"] + fafhCoef[,,"b_fafh"] * gdp
    fafhShr[fafhShr > 1] <- 1
    fafhShr[fafhShr < 0 ] <- 0

     
  avExp = collapseNames(
    fafhShr[, getYears(kcalPcIso), ] * kcalPcIso * marginFAFH[, getYears(kcalPcIso), ] + 
      (1-fafhShr[, getYears(kcalPcIso), ]) * kcalPcIso * marginFAH[, getYears(kcalPcIso), ])
  } 

   avExp <- convertGDP(avExp,  unit_in = "constant 2017 US$MER",
                       unit_out = "constant 2017 Int$PPP",
                       replace_NAs = "with_USA")
  avExp <- avExp * popiso
  }

  if(after_shock==TRUE){
    price = FoodDemandModuleConsumerPrices(gdx)

    value = price *
      Kcal(gdx=gdx,
        level="iso",
        calibrated=TRUE,
        after_shock = TRUE,
        products="kfo",
        product_aggr = FALSE,
        per_capita=FALSE
      )

    if (valueAdded) {
      value <- value + avExp
    }

    out<-gdxAggregate(
      gdx=gdx,
      x=value,
      weight="Kcal",
      to=level,
      absolute=TRUE,

      #arguments of weight
      calibrated=TRUE,
      after_shock = TRUE,
      products="kfo",
      product_aggr = FALSE,
      per_capita=FALSE

    )

  } else if (after_shock=="after_price_before_demand") {
    value = FoodDemandModuleConsumerPrices(gdx) *    #prices with shock
      Kcal(gdx=gdx,
        level="iso",
        calibrated=TRUE,
        after_shock = FALSE,  #demand without shock
        products="kfo",
        product_aggr = FALSE,
        per_capita=FALSE

      )

    if (valueAdded) {
      value <- value + avExp
    }

    out<-gdxAggregate(
      gdx=gdx,
      x=value,
      weight="Kcal",
      to=level,
      absolute=TRUE,


      #arguments of weight
      calibrated=TRUE,
      after_shock = FALSE,
      products="kfo",
      product_aggr = FALSE,
      per_capita=FALSE

    )
  } else if (after_shock==FALSE){
    value = readGDX(gdx,"i15_prices_initial_kcal") *
      Kcal(gdx=gdx,
        level="iso",
        calibrated=TRUE,
        after_shock = FALSE,
        products="kfo",
        product_aggr = FALSE,
        per_capita=FALSE

      )


    if (valueAdded) {
      value <- value + avExp
    }

    out<-gdxAggregate(
      gdx=gdx,
      x=value,
      weight="Kcal",
      to=level,
      absolute=TRUE,

      #arguments of weight
      calibrated=TRUE,
      after_shock = FALSE,
      products="kfo",
      product_aggr = FALSE,
      per_capita=FALSE

    )
  } else {stop("after_shock has to be binary")}

  if (per_capita==TRUE){
    pop<-population(gdx,level=level)
    out=out/pop
    out[is.nan(out)]<-0
  }

  if(products=="kall"){
    missing<-setdiff(readGDX(gdx,"kall"),getNames(out))
    out<-add_columns(out,addnm = missing,dim = 3.1)
    out[,,missing]<-0
    products<-findset(products)
  } else if (!products%in%getNames(out)){
    products<-findset(products)
  }

  out<-out[,,products]*365  ## transform into dollar per year

  if(product_aggr){out <- dimSums(out,dim=3.1)}

  return(out)
}
