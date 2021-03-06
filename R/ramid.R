# inFile="out.csv";ouFile="ramidout.csv";cdfzip="data/SW620.zip"
sset<-function(rd,nm,nar){ # rd=Metabolights data frame, nm=column number with pattern for subsetting;
#  nar=list of patterns used
  ordd<-data.frame()
    naz<-as.character(rd[5,nm]) #file name
    narr<-c(nar,naz) #array of file names
    ordd<-subset(rd, subset=(as.character(rd[,nm])==naz)) # rows for selected metaboliite
    rdd<-subset(rd, subset=(as.character(rd[,nm])!=naz))  # rest of rows
return(list(ordd,rdd,narr,naz))
}
basln<-function(vec,pos=length(vec),ofs=0){# baseline
   basl<--1; basr<--1;bas<-0
  if(pos>ofs) basl<-mean(vec[1:(pos-ofs)])
  if(pos<(length(vec)-ofs)) basr<-mean(vec[(pos+ofs):length(vec)])
  if((basl>0)&(basr>0)) bas<-min(basl,basr)
  else if(basl<0) bas<-basr
  else if(basr<0) bas<-basl
 return(bas)}

ruramid<-function(inFile="exam1in.csv",ouFile="exam1ou.csv",cdfzip="data/exam1.zip"){
 temp <- paste(tempdir(),"/",sep="")  #"data/ttt/"  #
 lf<-unzip(cdfzip,exdir=temp)
# lcdf<-dir(path="./data/temp",pattern=".CDF") # list of names of ".CDF" files
 print(lf)

  fn<-inFile  #file.path(paste("./",inFile,sep=""));
  rada<-read.table(inFile, sep=',');   # read experimental data
   tit<-rada[1,] # copy titles
    write.table(tit, file=ouFile, sep=",", row.names = F, col.names = F)
  for(i in 1:ncol(rada)) {
        if(grepl("m/z",rada[1,i])) imz<-i # get a column of mz
        if(grepl("retent",rada[1,i])) iret<-i # get a column of retentions
        if(grepl("signal",rada[1,i])) iint<-i # get a column of intensity
        if(grepl("Metab",rada[1,i])) inaz<-i # get a column of metabolite names
        if(grepl("atomic",rada[1,i])) ifrg<-i # get a column of names
  }
  rda<-rada
  fiar=character()
  rtdev<-15; imya<-1
  ord<-data.frame()
  while(nrow(rda)>5){
# select file names
     a<-sset(rd=rda,nm=imya,nar=fiar)
      ord<-droplevels(a[[1]]); rda<-droplevels(a[[2]]); fiar<-a[[3]]; fimya<-a[[4]]
      tfi<-paste(temp,fimya,sep="")
      if(!grepl('.CDF',fimya)) tfi<-paste(temp,fimya,".CDF",sep="")
     a<-readcdf(tfi) # read mz, intensities, number of mz-point, sum of iv at each rett
      mz<-a[[1]]; iv<-a[[2]]; npoint<-a[[3]]; rett<-a[[4]];
     a<-info(mz,iv,npoint);                     # summary of CDF file content
      mzpt<-a[[1]]; tpos<-a[[2]]; mzind<-a[[3]]; mzrang<-a[[4]]; 
# select metabolites names in the selected file
    metar=character()
    ord1<-data.frame()
   while(nrow(ord)>3){
     a<-sset(rd=ord,nm=inaz,nar=metar)
      ord1<-droplevels(a[[1]]); ord<-droplevels(a[[2]]); metar<-a[[3]]; mimya<-a[[4]]
# select fragments of selected metabolites
      frar=character()
      ord2<-data.frame()
    while(nrow(ord1)>3){
        a<-sset(rd=ord1,nm=ifrg,nar=frar)
        ord2<-droplevels(a[[1]]); ord1<-droplevels(a[[2]]); frar<-a[[3]]; frimya<-a[[4]]
      retim<-as.numeric(as.character(ord2[1,iret]))
      mz0<-as.numeric(as.character(ord2[1,imz]))
      cfrg<-strsplit(as.character(ord2[1,ifrg]),'C')[[1]]
      nCfrg<-as.numeric(cfrg[3])-as.numeric(substr(cfrg[2],1,1))+1
      nmass<-nCfrg+5 # number of isotopomers to present
     rts<-retim*60.;
     ranum<-integer()
# ** Extraction of peaks starts here **
# select m/z range corresponding to the selrcted fragment
        for(i in 1:length(mzrang))
 if((mz0 %in% round(mzrang[[i]],1)) & (rts>rett[tpos[i]]) & (rts<rett[tpos[i+1]-5])){ ranum<-i; break }
        tpclose<-which.min(abs(rett-rts));  tlim=50
        tplow<-max(tpclose-tlim,tpos[ranum]);
        tpup<-min(tpclose+tlim,tpos[ranum+1])     # boundaries that include desired peak
   mzi<-mzind[ranum]+mzpt[ranum]*(tplow-tpos[ranum])#index of initial mz point
   mzfi<-mzi+mzpt[ranum]*(tpup-tplow)   	#index of final mz point
   rtpeak<-rett[tplow:tpup] # retention times within the boundaries
        tpclose<-which.min(abs(rtpeak-rts))
      
    misofin<-array(mz0:(mz0+nmass)) # isotopores to present in the spectrum
    lmisofin<-round(mzrang[[ranum]],1) %in% round(misofin,1) # do they are present in the given mzrang?
    pikmz<-mzrang[[ranum]][lmisofin] # extrat those that are present
    nmass<-length(pikmz)
    
    intens<-matrix(ncol=nmass,nrow=(tpup-tplow),0)
    intens<-sweep(intens,2,iv[mzi:mzfi][lmisofin],'+') # create matrix iv(col=mz,row=rt) that includes the peak
     pospiks<-apply(intens,2,which.max)
     pikint<-apply(intens,2,max)
   if(max(abs(diff(pospiks)))>9) goodiso<-which.min(abs(pospiks-tpclose))  else goodiso<-which.max(pikint)
        pikpos<-pospiks[goodiso]
     
  if((abs(pikpos-tpclose)<rtdev)&(pikpos>2)&(pikpos<(nrow(intens)-2))) {
        maxpik<-pikint[goodiso]
     if(maxpik>8300000) {smaxpik<-"**** !?MAX_PEAK:"; print(paste("** max=",maxpik,"   ",mimya,"   **")); next }
        piksum<-numeric()
    for(k in 1:nmass) piksum[k]<-sum(intens[(pikpos-2):(pikpos+2),k])
      bas<-5*round(apply(intens,2,basln,pos=pikpos,ofs=5))
                delta<-round(piksum-bas)
    if((misofin[1]==pikmz[1])&(delta[1]/delta[2] > 0.075)) { s5tp<-"*!?* 5_timepoints:";
      print(paste("+++ m-1=",delta[1],"  m0= ",delta[2],"   +++ ",mimya)); next }
                rat<-delta/bas
     iso<-character()
     for(i in 1:nmass)iso[i]<-paste(substr(mimya,1,3),"_13C",i-2,sep="")
     tab<-cbind(ord2[1,1:iret],round(pikmz),delta,iso," ")
    write.table(tab, file=ouFile, sep=",", row.names = F, col.names = F, append=T)
	}
      }
    }
  }
    unlink(temp, recursive = T, force = T)
}

info<-function(mz,iv,npoint){
#  mz,iv,npoint: mz, intensities and number mz points in every scan
      j<-1
  mzpt<-numeric() # number of m/z points in each pattern
  tpos<-numeric() # initial time position for each m/z pattern 
   mzi<-numeric() # initial value for each m/z pattern presented in the CDF file
    mzind<-numeric() # index in mz array corresponding to mzi
     mzrang<-list() # list of mz patterns presented in the .CDF
  mzpt[j]<-npoint[1]; tpos[j]<-1; mzi[j]<-mz[1]; imz<-1; mzind[j]<-imz
  mzrang[[1]]<-mz[1:mzpt[1]];
    for(i in 2:length(npoint)) { imz<-imz+npoint[i-1];
     if(mzi[j]!=mz[imz]){  j<-j+1; tpos[j]<-i;  mzpt[j]<-npoint[i]; mzi[j]<-mz[imz];
      mzind[j]<-imz; mzrang[[j]]<-mz[(mzind[j]):(mzind[j]-1+mzpt[j])] }
    }
  tpos[length(tpos)+1]<- length(npoint) # add the last timepoint
  return(list(mzpt,tpos,mzind,mzrang))
  }
  
findmax<-function(totiv,tin,tfi){
  totiv1<-totiv[tin:(tfi-1)]
  nma<-which.max(totiv1);
  return(nma)}
  

#       for(fi in lcdf){itrac<-0 #labname<-" "; labpos<-" "; abund<-" "; ti<-0 #CDF files one by one
#     a <-findpats(fi,finames,ldf);
#     finames<-a[[1]]; ldf<-a[[2]]   # output 1: reltive intensities; 2: relative peak areas;
# if(length(a)>1)  { ifi<-ifi+1; mzr<-a[[3]]; imet<-a[[4]]; dist<-a[[5]];
#        for(j in 1:length(imet)) {data=metabs[[imet[j]]]; miso=character(); miso=paste("13C",mzr[[j]]-data$mz0,sep="") #isotopomer names
#  dfrow<-data.frame(fi,cel,labname,labpos,abund,tinc,data$metname,data$chebi,data$Cfrg,data$Cder,data$rt, mzr[[j]], c(0,dist[[j]]), miso," ")
#  df0<-rbind(df0,dfrow) # filling df with dfrow
#     }
#     }
#       }
  peakdist<-function(intens,rett1,tlim=50,peakf=5,ipmi=5,stabin=2){
# fi: file name
# met: parameters of metabolite (mz for m0, retention time)
# ilim: number of points limiting half peak
# peakf: factor to define lower limit of peak interval used for fitting
# ipmi: minimal number of points for half peak taken for fitting
# stabin: numer of points after peak to defing mi ratio
   inmax<-which.max(intens[tlim,]); porog<-intens[tlim,inmax]/peakf
   ip<-1; while(intens[tlim-ip,inmax]>porog & intens[tlim+ip,inmax]>porog) ip<-ip+1
   if(ip<ipmi) ip<-ipmi
  mm1=eimpact(intens)      # correct electron impact
  mm0=rowfr(mm1)        # normalization
   a<-fitdist(rett1,mm1,tlim,pint=ip)
   reti<-a[[1]]; ye<-a[[2]]; yf<-a[[3]]; area<-a[[4]]
    relar<-area/sum(area)
#    savplt(intens,mm0,nma,fi)
#    plal(fi,reti,ye,yf)
 return(list(mm0[tlim,],relar))#MID calculated as ratio either of intensities or areas of fitted peaks
  }

#  
#     
# nma1= which.max(mm0[(nma):(nma+stabin),1])
# prep= nma1+nma-1; # print(prep)
# list(mm0[prep,],relar,mzr)
# }
#     
#   
#  return(list(mativ,rett1,totiv1,mzr))
## mativ: matrix of intensities corresponding to various mz in rows and to retention times in columns, corresponding to metp
## rett1: vector of retention times, corresponding to metp
## totiv1: sum of intensities in each row
#}

fitG <-function(x,y,mu,sig,scale){
# x,y: x and y values for fitting
# mu,sig,scale: initial values for patameters to fit  
  f = function(p){
    d = p[3]*dnorm(x,mean=p[1],sd=p[2])
    sum((d-y)^2)
  }
  optim(c(mu,sig,scale),f,method="CG")
 # nlm(f, c(mu,sig,scale))
# output: optimized parameters
   }
  
fitdist<-function(x,ymat,nma,pint=5,cini=2,fsig=1.5,fsc=2.){ # fits distributions
# x: vector of x-values
# ymat: matrix of experimental values where columns are time courses for sequential mz
# nma: point of maximal value
# pint: half interval taken for fitting
# cini: initial column number
  cfin<-ncol(ymat)#cini+nmi-1;
  nmi<-cfin-cini+1 #ncol(ymat)-1;
   fscale<-numeric()
   xe<-x[(nma-pint):(nma+pint)];    facin<-max(ymat[nma,]);
   yemat<-ymat[(nma-pint):(nma+pint),cini:cfin]/facin
      yfmat<-yemat
          mu<-xe[pint+1]
          sig<-(xe[2*pint]-xe[2])/fsig
   for(i in 1:nmi){
          scale<-yemat[pint,i]*sig/fsc
   fp<-fitG(xe,yemat[,i],mu,sig,scale)
    fscale[i]<-fp$par[3]*facin
    yfmat[,i]<-fp$par[3]*dnorm(xe,mean=fp$par[1],sd=fp$par[2])
#    fscale[i]<-fp$estimate[3]*facin
#    yfmat[,i]<-fp$estimate[3]*dnorm(xe,mean=fp$estimate[1],sd=fp$estimate[2])
#   mu<-fp$par[1];  sig<-fp$par[2];# scale<-fp$par[3]
   }
   list(xe,yemat,yfmat,fscale)
#   xe: x-values used for fit
#   yemat: matrix of experimental intensities
#   yfmat: matrix of fitted intensities
#   fscale: areas of peaks
}
     
plal<-function(fi,x,me,mf){# plots intensities from matrix mm; nma - position of peaks; abs - 0 or 1 depending on mm
# fi: file to plot in
# x: vector of x-values
# me: matrix of experimental values where columns are time courses for sequential mz
# mf: matrix of fittings corresponding to me
    fi<-strsplit(fi,"CDF")[[1]][1]
  png(paste("../graf/",fi,"png",sep=""))
  x_range<-range(x[1],x[length(x)])
  g_range <- range(0,1)
  nkriv<-ncol(me); sleg<-"m0"
  plot(x,me[,1], xlim=x_range, ylim=g_range,col=1)
  lines(x,mf[,1],col=1, lty=1)
   for(i in 2:nkriv){ sleg<-c(sleg,paste("m",i-1))
    points(x,me[,i],pch=i,col=i)
    lines(x,mf[,i],col=i, lty=i)
  }
  legend("topright",sleg,col = 1:length(sleg),lty=1:length(sleg))
   dev.off()
   }
     
