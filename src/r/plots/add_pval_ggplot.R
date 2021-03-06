add_pval_ggplot <- function(ggplot_obj, pairs=list(c(1,2),c(1,3)),heights=NULL,barheight=0.05,method='wilcox.test',
                            size=8,pval_text_adj=0.1,annotation=NULL,log=TRUE, pval_star=FALSE){
  require(data.table)
  facet <- NULL # Diffault no facet
  # Check whether facet
  if (class(ggplot_obj$facet)[1]!='null'){
    if (length(names(ggplot_obj$facet$cols)) > 1){
      stop('Not yet implemented for grid facet with two variables, feel free to do it!')
    }else{
      #facet <- names(ggplot_obj$facet$cols)
      facet <- ggplot_obj$facet$params$facets[[1]]
    }
  }
  
  if(!is.null(heights)){
    
    if(length(pairs) != length(heights)){
      
      stop('the heights of the pvalue bar should be the same length as pairs. Otherwise, calculate from the data')
      
    }
    
  }
  
  # make sure group and response column are identified
  
  ggplot_obj$data <- data.table(ggplot_obj$data)
  
  ggplot_obj$data$group <- ggplot_obj$data[ ,get(get_in_parenthesis(strsplit(as.character(ggplot_obj$mapping)[1],'->')$x))]
  
  ggplot_obj$data$response <- ggplot_obj$data[ ,get(get_in_parenthesis(strsplit(as.character(ggplot_obj$mapping)[2],'->')$y))]
  
  # make sure group is factor
  
  ggplot_obj$data$group <- factor(ggplot_obj$data$group)
  
  # Barheight and pval text
  
  if(length(pval_text_adj) != length(pairs)){
    
    pval_text_adj <- rep(pval_text_adj,length=length(pairs))
    
    warning('Length of pval_text_adj not equals to length of pairs, recycled!')
    
  }
  
  if(length(barheight) != length(pairs)){
    
    barheight <- rep(barheight,length=length(pairs))
    
    warning('Length of barheight not equals to length of pairs, recycled!')
    
  }
  
  # Scale barheight and pval_text_adj log
  
  if (log){
    
    barheight <- exp(log(heights) + barheight) - heights
    
    pval_text_adj <- exp(log(heights) + pval_text_adj) - heights
    
  }
  
  # for each pair, build a data.frame with pathess
  
  for(i in seq(length(pairs))){
    
    if(length(unique(pairs[[1]]))!=2){
      
      stop('Each vector in pairs must have two different groups to compare, e.g. c(1,2) to compare first and second box.')
      
    }
    
    test_groups <- levels(ggplot_obj$data$group)[pairs[[i]]]
    
    # subset the data to calculate p-value
    
    data_2_test <- ggplot_obj$data[ggplot_obj$data$group %in% test_groups,]
    
    # statistical test
    
    # Need facet is present
    
    if (!is.null(facet)){
      
      pval <- data_2_test[ , lapply(.SD, function(i) wilcox.test(response ~ as.character(group))$p.value), by=facet, .SDcols=c('response','group')]
      
      pval <- pval[,group]
      
    }else{
      
      pval <- get(method)(data=data_2_test, response ~ group)$p.value
      
      fc <- data_2_test[, median(response), by = group][order(group)][, .SD[1] / .SD[2], .SDcols='V1'][,V1]
      
      fc <- paste0('FC=', round(fc, digits = 2))
      
      pval <- paste(pval, fc)
      
    }
    
    # convert pval to stars if needed
    
    if (pval_star){
      
      pval <- pvars2star(pval)
      
      annotation <- pval
      
    }
    
    # make data from of label path, the annotation path for each facet is the same
    
    if(is.null(heights)){
      
      height <- max(data_2_test$response)
      
    }else{
      
      height <- heights[i]
      
    }
    
    df_path <- data.frame(group=rep(pairs[[i]],each=2),response=c(height,height+barheight[i],height+barheight[i],height))
    
    ggplot_obj <- ggplot_obj + geom_line(data=df_path,aes(x=group,y=response,fill=NULL))
    
    if(is.null(annotation)){ # assume annotate with p-value
      
      labels <- sapply(pval, function(i) deparse(format_pval(i)))
      
      ggplot_obj <- ggplot_obj + annotate("text",
                                          
                                          x = (pairs[[i]][1]+pairs[[i]][2])/2,
                                          
                                          y = height+barheight[i]+pval_text_adj[i],
                                          
                                          #label = "paste(italic('P'), pval)", size = size, parse=TRUE) # pval not as number
                                          
                                          label = labels, size = size, parse=TRUE)
      
      #label = paste('P =', pval), size = size)
      
      # TODO: if p<2.226e-16, the function will still display p=<2.226e-16
      
    }else{
      
      if(length(annotation) != length(pairs)){
        
        annotation <- rep(annotation,length=length(pairs))
        
        warning('Length of annotation not equals to length of pairs, recycled!')
        
      }
      
      ggplot_obj <- ggplot_obj + annotate("text", x = (pairs[[i]][1]+pairs[[i]][2])/2, y = height+barheight[i]+pval_text_adj[i], label = annotation[i], size = size)
      
    }
    
  }
  
  ggplot_obj
  
}


### Functions needed for the previous add_pval function

get_in_parenthesis <- function(str){
  if(grepl(')',str)){
    str = regmatches(str, gregexpr("(?<=\\().*?(?=\\))", str, perl=T))[[1]]
  }
  str
}

format_pval <- function(pval){
  pval <- base::format.pval(pval, digits = 3)
  if (grepl("<", pval)){
    pval <- gsub("< ?", "", pval)
    pval <- bquote(italic(P) < .(pval))
  }else{
    pval <- bquote(italic(P) == .(pval))
  }
  pval
}

pvars2star <- function(pvars){   
  pvars <- ifelse(pvars<0.001,'***',ifelse(pvars<0.01,'**',ifelse(pvars<0.05,'*',ifelse(pvars<0.1,'',''))))   
  return(pvars) 
}