
c=======================================================================                      
      subroutine dpglmmlogit(
     &             datastr,maxni,nrec,nsubject,nfixed,p,q,              
     &             subject,x,xtx,y,yr,z,a0b0,nu0,prec,psiinv,sb,smu,    
     &             tinv,mcmc,nsave,randsave,thetasave,cpo,alpha,b,bclus,
     &             beta,betar,mu,ncluster,sigma,ss,mc,cstrt,ccluster,   
     &             iflag,iflag2,iflagb,prob,quadf,res,seed,             
     &             sigmainv,theta,workb1,workb2,                        
     &             workmh1,workmh2,workmh3,workk1,workkv1,workkm1,      
     &             workkm2,workv1,workvb1,workvb2,xty,ywork,zty,        
     &             ztz,lambda,betasave,bsave)                           
c=======================================================================                      
c     # of arguments = 65.
c
c     Subroutine `dpglmmlogit' to run a Markov chain in the 
c     semiparametric logit mixed model using a Dirichlet Process prior 
c     for the distributions of the random effecs. In this routine, 
c     inference is based on the Polya urn representation of Dirichlet 
c     process.
c
c     Copyright: Alejandro Jara, 2006-2010.
c
c     Version 2.0: 
c
c     Last modification: 25-04-2007.
c
c     Changes and Bug fixes: 
c
c     Version 1.0 to Version 2.0:
c          - The "population" parameters betar are computed as a 
c            functional of a DP instead of base on simple averages of
c            the random effects.
c          - The computation of the DIC was added.
c
c     This program is free software; you can redistribute it and/or modify
c     it under the terms of the GNU General Public License as published by
c     the Free Software Foundation; either version 2 of the License, or (at
c     your option) any later version.
c
c     This program is distributed in the hope that it will be useful, but
c     WITHOUT ANY WARRANTY; without even the implied warranty of
c     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
c     General Public License for more details.
c
c     You should have received a copy of the GNU General Public License
c     along with this program; if not, write to the Free Software
c     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
c
c     The author's contact information:
c
c      Alejandro Jara
c      Department of Statistics
c      Facultad de Matematicas
c      Pontificia Universidad Catolica de Chile
c      Casilla 306, Correo 22 
c      Santiago
c      Chile
c      Voice: +56-2-3544506  URL  : http://www.mat.puc.cl/~ajara
c      Fax  : +56-2-3547729  Email: atjara@uc.cl
c
c---- Data -------------------------------------------------------------
c 
c        datastr     :  integer matrix giving the number of measurements
c                       and the location in y of the observations for 
c                       each subject, datastr(nsubject,maxni+1)
c        maxni       :  integer giving the maximum number of 
c                       measurements for subject.
c        nrec        :  integer giving the number of observations.
c        nsubject    :  integer giving the number of subjects.
c        nfixed      :  integer giving the number of fixed effects,
c                       if nfixed is 0 then p=1.
c        p           :  integer giving the number of fixed coefficients.
c        q           :  integer giving the number of random effects.
c        subject     :  integer vector giving the subject for each.
c                       observation, subject(nsubject).
c        x           :  real matrix giving the design matrix for the 
c                       fixed effects, x(nrec,p). 
c        y           :  real vector giving the response variable,
c                       y(nrec).
c        z           :  real matrix giving the design matrix for the 
c                       random effects, z(nrec,q). 
c-----------------------------------------------------------------------
c
c---- Prior information ------------------------------------------------
c 
c        aa0, ab0    :  real giving the hyperparameters of the prior
c                       distribution for the precision parameter,
c                       alpha ~ Gamma(aa0,ab0). If aa0<0 the precision 
c                       parameter is considered as a constant.
c        nu0         :  integer giving the degrees of freedom for the
c                       inverted-Wishart prior distribution for the
c                       covariance matrix of the random effects
c                       (This is for the base line).
c        prec        :  real matrix giving the prior precision matrix
c                       for the fixed effects, prec(p,p).
c        psiinv      :  real matrix giving the prior precision matrix
c                       for the baseline mean, psiinv(q,q).
c        sb          :  real vector giving the product of the prior 
c                       precision and prior mean for the fixed effects,
c                       sb(p).
c        smu         :  real vector giving the product of the prior 
c                       precision and prior mean for the baseline mean,
c                       smu(q).
c        tinv        :  real matrix giving the scale matrix for the
c                       inverted-Wishart prior distribution for the
c                       covariance matrix of the random effects, 
c                       sigma ~ Inv-Wishart(nu0,tinv^{-1}), such that 
c                       E(sigma)=(1/(nu0-q-1)) * tinv 
c                       (This is for the base line distribution)
c-----------------------------------------------------------------------
c
c---- MCMC parameters --------------------------------------------------
c
c        nburn       :  integer giving the number of burn-in scans.
c        ndisplay    :  integer giving the number of saved scans to be
c                       displayed on screen.
c        nskip       :  integer giving the thinning interval.
c        nsave       :  integer giving the number of scans to be saved.
c        
c-----------------------------------------------------------------------
c
c---- Output -----------------------------------------------------------
c
c        cpo         :  real giving the cpo. 
c        randsave    :  real matrix containing the mcmc samples for
c                       the random effects and prediction,
c                       randsave(nsave,q*(nsubject+1))
c                       thetsave(nsave,q+nfixed+1+q+nuniq(Sigma)+2).
c        thetasave   :  real matrix containing the mcmc samples for
c                       the averaged random effects, fixed effects, 
c                       error variance, and mean and covariance of
c                       the baseline distribution, 
c                       thetsave(nsave,q+nfixed+q+nuniq(Sigma)+2).
c
c-----------------------------------------------------------------------
c
c---- Current value of the parameters ----------------------------------
c
c        alpha       :  real giving the current value of the precision
c                       parameter of the Dirichlet process.
c        b           :  real matrix giving the current value of the 
c                       random effects, b(nsubject,q).
c        bclus       :  real matrix giving the current value of the 
c                       different values of random effects, 
c                       bclus(nsubject,q).
c        beta        :  real vector giving the current value of the 
c                       fixed effects, beta(p).
c        betar       :  real vector giving the current value of the 
c                       averaged random effects, betar(q).
c        lambda      :  real vector giving the current value of the
c                       scale parameters.
c        mu          :  real vector giving the mean of the normal 
c                       base line distribution for the random effects,
c                       mu(q).
c        ncluster    :  integer giving the number of clusters in the
c                       random effects.
c        sigma       :  real matrix giving the current value of the
c                       covariance matrix for normal base line 
c                       distribution for the random effects,
c                       sigma(q,q).
c        sigmainv    :  real matrix used to save the base line 
c                       covariance matrix for the random effects,
c                       sigmainv(q,q).
c        ss          :  integer vector giving the cluster label for 
c                       each subject, ss(nsubject).
c-----------------------------------------------------------------------
c
c---- Working space ----------------------------------------------------
c
c        ccluster    :  integer vector indicating the number of
c                       subjects in each cluster, ccluster(nsubject).
c        cstrt       :  integer matrix used to save the cluster
c                       structure, cstrt(nsubject,nsubject).
c        detlog      :  real used to save the log-determinant in a
c                       matrix inversion process.
c        dispcount   :  index. 
c        evali       :  integer indicator used in updating the state.
c        i           :  index. 
c        ii          :  index. 
c        iflag       :  integer vector used to invert the of the lhs
c                       least square solution for the fixed effects,
c                       iflag(p).
c        iflag2      :  integer vector used to invert the of the 
c                       covariance matrix for each subject,
c                       iflag2(maxni).
c        iflagb      :  integer vector used to invert the of the lhs
c                       least square solution for the random effects,
c                       iflagb(q).
c        isave       :  index. 
c        iscan       :  index. 
c        j           :  index. 
c        k           :  index. 
c        l           :  index.
c        prob        :  real vector used to update the cluster 
c                       structure, prob(nsubject+1).
c        quadf       :  real matrix used to save the bilinear product
c                       of random effects, quadf(q,q).
c        ni          :  integer indicator used in updating the state. 
c        ns          :  integer indicator used in updating the state. 
c        nscan       :  integer indicating the total number of MCMC
c                       scans.
c        res         :  real vector used to save the residual effects,
c                       res(nrec).
c        seed1       :  seed for random number generation.
c        seed2       :  seed for random number generation.
c        seed3       :  seed for random number generation.
c        since       :  index.
c        skipcount   :  index. 
c        theta       :  real vector used to save randomnly generated
c                       random effects, theta(q).
c        tmp1        :  real used to accumulate quantities. 
c        tmp2        :  real used to accumulate quantities.
c        tmp3        :  real used to accumulate quantities.
c        tpi         :  real parameter used to evaluate the normal 
c                       density.
c        workb1      :  real matrix used to update the random effects,
c                       workb1(q,q).
c        workb2      :  real matrix used to update the random effects,
c                       workb2(q,q).
c        workmh1     :  real vector used to update the fixed effects,
c                       workmh1(p*(p+1)/2)
c        workmh2     :  real vector used to update the random effects,
c                       workmh2(q*(q+1)/2)
c        workmh3     :  real vector used to update the random effects,
c                       workmh3(q*(q+1)/2)
c        workk1      :  real matrix used to update the cluster 
c                       structure, workk1(maxni,q)
c        workkv1     :  real vector used to update the cluster 
c                       structure, workkv1(maxni)
c        workkm1     :  real matrix used to update the cluster 
c                       structure, workkm1(maxni,maxni).
c        workkm2     :  real matrix used to update the cluster 
c                       structure, workkm2(maxni,maxni).
c        workv1      :  real vector used to update the fixed effects,
c                       workv1(p)
c        workvb1     :  real vector used to update the random effects,
c                       workvb1(p)
c        workvb2     :  real vector used to update the random effects,
c                       workvb2(p)
c        xtx         :  real matrix givind the product X^tX, xtx(p,p).
c        xty         :  real vector used to save the product 
c                       Xt(Y-Zb), xty(p).
c        ywork       :  real vector used to save the measurement for
c                       a particular subject, ywork(maxni).
c        zty         :  real vector used to save the product 
c                       Zt(Y-Xbeta), zty(q).
c        ztz         :  real matrix used to save the product 
c                       ZtSigma^1Z, ztz(q,q).
c=======================================================================                  
      implicit none 

c+++++Data
      integer maxni,nrec,nsubject,nfixed,p,q,subject(nrec)
      integer datastr(nsubject,maxni+1),yr(nrec)
      double precision y(nrec),x(nrec,p),z(nrec,q)
      
c+++++Prior 
      integer nu0,murand,sigmarand
      double precision aa0,ab0,a0b0(2),prec(p,p),psiinv(q,q)
      double precision sb(p),smu(q)
      double precision tinv(q,q)      

c+++++MCMC parameters
      integer mcmc(5),nburn,nskip,nsave,ndisplay

c+++++Output
      double precision cpo(nrec,2)
      double precision randsave(nsave,q*(nsubject+1))
      double precision thetasave(nsave,q+nfixed+q+(q*(q+1)/2)+2)

c+++++Current values of the parameters
      integer ncluster,ss(nsubject)
      double precision alpha,beta(p),b(nsubject,q)
      double precision betar(q),bclus(nsubject,q)
      double precision lambda(nrec)
      double precision mu(q),sigma(q,q),sigmainv(q,q)

c+++++Seeds
      integer seed(2),seed1,seed2

c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c+++++External working space
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

c+++++fixed effects
      integer iflag(p)
      double precision workmh1(p*(p+1)/2)
      double precision workv1(p)
      double precision xtx(p,p)
      double precision xty(p)

c+++++random effects
      integer iflag2(maxni),iflagb(q)
      double precision theta(q)
      double precision workb1(q,q),workb2(q,q)
      double precision workmh2(q*(q+1)/2),workmh3(q*(q+1)/2)
      double precision workk1(maxni,q)
      double precision workkm1(maxni,maxni),workkm2(maxni,maxni)
      double precision workkv1(maxni),workvb1(q),workvb2(q)
      double precision ywork(maxni)
      double precision zty(q),ztz(q,q)

c+++++DP
      integer cstrt(nsubject,nsubject)
      integer ccluster(nsubject)
      double precision prob(nsubject+1)

c+++++Centering variance
      double precision quadf(q,q)

c+++++Residuals
      double precision res(nrec)

c++++ model's performance
      double precision mc(5)
      double precision betasave(p),bsave(nsubject,q)

c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c+++++Internal working space
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

c+++++General
      integer evali,ii,i,j,k,l,ni,ns,ok 
      integer since,sprint 
      double precision detlog,sigma2e
      double precision tmp1,tmp2,tmp3,tpi
      parameter(tpi=6.283185307179586476925286766559d0)
      logical ainf,asup
      
c+++++MCMC
      integer dispcount,isave,iscan,nscan,skipcount 

c+++++RNG and distributions
      double precision dbin,rtnorm
      
c+++++DP
      double precision eps,rbeta,weight
      parameter(eps=0.01)

c++++ model's performance
      double precision dbarc,dbar,dhat,pd,lpml

c+++++CPU time
      double precision sec00,sec0,sec1,sec

c++++ parameters
      nburn=mcmc(1)
      nskip=mcmc(2)
      ndisplay=mcmc(3)
      murand=mcmc(4)
      sigmarand=mcmc(5)

      aa0=a0b0(1)
      ab0=a0b0(2)
      
      sigma2e=1.d0
      
c++++ set random number generator
      seed1=seed(1)
      seed2=seed(2)
      call setall(seed1,seed2)
     
c++++ set configurations
      do i=1,nsubject
         ccluster(ss(i))=ccluster(ss(i))+1
         cstrt(ss(i),ccluster(ss(i)))=i
      end do
      
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c++++ start the MCMC algorithm
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      dbar=0.d0
      isave=0
      skipcount=0
      dispcount=0
      nscan=nburn+(nskip+1)*(nsave)

      call cpu_time(sec0)
      sec00=0.d0
      
      do iscan=1,nscan

c+++++++ check if the user has requested an interrupt
         call rchkusr()

c++++++++++++++++++++++++++++++++++
c+++++++ latent variable
c++++++++++++++++++++++++++++++++++

         do i=1,nrec
            tmp1=0.d0
            if(nfixed.gt.0)then
              do j=1,p
                 tmp1=tmp1+x(i,j)*beta(j)
              end do
            end if
            
            do j=1,q
               tmp1=tmp1+z(i,j)*b(subject(i),j) 
            end do
            
            sigma2e=sqrt(lambda(i))
            
            if(yr(i).eq.1)then
              ainf=.false.
              asup=.true.
              y(i)=rtnorm(tmp1,sigma2e,0.d0,0.d0,ainf,asup) 
            end if
            
            if(yr(i).eq.0)then
              ainf=.true.
              asup=.false.
              y(i)=rtnorm(tmp1,sigma2e,0.d0,0.d0,ainf,asup) 
            end if
         end do
         
c++++++++++++++++++++++++++++++++++
c+++++++ fixed effects
c++++++++++++++++++++++++++++++++++

         if(nfixed.gt.0)then
            do i=1,p
               do j=1,p
                  xtx(i,j)=prec(i,j)
               end do
               xty(i)=sb(i)
            end do

            do i=1,nrec
               tmp1=0.d0
               do j=1,q
                  tmp1=tmp1+z(i,j)*b(subject(i),j) 
               end do
               tmp1=y(i)-tmp1
               
               sigma2e=lambda(i)
             
               do j=1,p
                  do k=1,p
                     xtx(j,k)=xtx(j,k)+x(i,j)*x(i,k)/sigma2e
                  end do
                  xty(j)=xty(j)+x(i,j)*(tmp1/sigma2e)
               end do
            end do

            call inverse(xtx,p,iflag) 

            do i=1,p
               tmp1=0.d0
               do j=1,p
                  tmp1=tmp1+xtx(i,j)*xty(j) 
               end do
               workv1(i)=tmp1
            end do
            call rmvnorm(p,workv1,xtx,workmh1,xty,beta)
         end if

         
c++++++++++++++++++++++++++++++++++         
c+++++++ random effects 
c++++++++++++++++++++++++++++++++++

c++++++++++++++++++++++++++++++
c+++++++ a) Polya Urn 
c++++++++++++++++++++++++++++++

         if(nfixed.eq.0)then
             do i=1,nrec
                res(i)=y(i) 
             end do
           else
             do i=1,nrec
                tmp1=0.d0
                do j=1,p
                   tmp1=tmp1+x(i,j)*beta(j)    
                end do
                res(i)=y(i)-tmp1
             end do
         end if  

         do i=1,nsubject
         
            ns=ccluster(ss(i))
            ni=datastr(i,1) 


c++++++++++ subject in cluster with more than 1 observations
             
            if(ns.gt.1)then

               j=1
               ok=0
               do while(ok.eq.0.and.j.le.ns)
                  if(cstrt(ss(i),j).eq.i)ok=j
                  j=j+1
               end do
   
               do j=ok,ns-1
                  cstrt(ss(i),j)=cstrt(ss(i),j+1)
               end do

               ccluster(ss(i))=ccluster(ss(i))-1 

               do j=1,ncluster
                  tmp3=0.d0
                  tmp2=0.d0
                  
                  do k=1,ni
                     tmp1=0.d0
                     do l=1,q
                        tmp1=tmp1+z(datastr(i,k+1),l)*bclus(j,l)
                     end do
                     
                     sigma2e=lambda(datastr(i,k+1))
                     
                     tmp2=tmp2+log(sigma2e)
                     
                     tmp1=res(datastr(i,k+1))-tmp1
                     
                     tmp3=tmp3+tmp1*tmp1/sigma2e
                  end do

                  tmp1=-(dble(ni)*log(tpi))

                  prob(j)=exp(log(dble(ccluster(j)))+
     &                        (tmp1-tmp2-tmp3)/2.d0)

               end do
               
               do j=1,ni
                  tmp1=0.d0
                  do k=1,q
                     tmp1=tmp1+z(datastr(i,j+1),k)*mu(k)
                  end do
                  ywork(j)=res(datastr(i,j+1))-tmp1
               end do
               
               do j=1,ni
                  do k=1,q
                     tmp1=0.d0
                     do l=1,q
                        tmp1=tmp1+z(datastr(i,j+1),l)*sigma(l,k)   
                     end do
                     workk1(j,k)=tmp1
                  end do
               end do
        
               do j=1,ni
                  do k=1,ni
                     tmp1=0.d0
                     do l=1,q
                       tmp1=tmp1+workk1(j,l)*z(datastr(i,k+1),l)
                     end do
                     workkm1(j,k)=tmp1
                  end do
               end do

               do j=1,ni
                  sigma2e=lambda(datastr(i,j+1))
                  workkm1(j,j)=workkm1(j,j)+sigma2e
               end do

               call invdet2(workkm1,maxni,ni,workkm2,detlog,iflag2,
     &                      workkv1)

               tmp1=-(dble(ni)*log(tpi))
               tmp2=detlog

               tmp3=0.d0
               do j=1,ni
                  do k=1,ni
                     tmp3=tmp3+ywork(j)*workkm2(j,k)*ywork(k)
                  end do
               end do
               
               prob(ncluster+1)=exp(log(alpha)+(tmp1-tmp2-tmp3)/2.d0)

               call simdisc(prob,nsubject+1,ncluster+1,evali)

               ss(i)=evali
               
               ccluster(evali)=ccluster(evali)+1

               cstrt(evali,ccluster(evali))=i
               
               if(evali.gt.ncluster)then
                  ncluster=ncluster+1
                  
                  do j=1,q
                     do k=1,q
                        tmp1=0.d0
                        do l=1,ni
                           sigma2e=lambda(datastr(i,l+1))
                        
                           tmp1=tmp1+z(datastr(i,l+1),j)*
     &                          z(datastr(i,l+1),k)/sigma2e
                        end do
                        ztz(j,k)=tmp1
                     end do
                  end do
                  
                  do j=1,q
                     do k=1,q
                        ztz(j,k)=ztz(j,k)+sigmainv(j,k)
                     end do
                  end do   

                  call inverse(ztz,q,iflagb)
                  
                  do j=1,q
                     tmp1=0.d0
                     do k=1,ni
                        sigma2e=lambda(datastr(i,k+1))
                        
                        tmp1=tmp1+z(datastr(i,k+1),j)*
     &                        res(datastr(i,k+1))/sigma2e
                     end do
                     zty(j)=tmp1
                  end do
                 
                  do j=1,q
                     tmp1=0.d0
                     do k=1,q
                        tmp1=tmp1+sigmainv(j,k)*mu(k)   
                     end do
                     zty(j)=zty(j)+tmp1
                  end do
                 
                  do j=1,q
                     tmp1=0.d0
                     do k=1,q
                        tmp1=tmp1+ztz(j,k)*zty(k) 
                     end do
                     workvb1(j)=tmp1
                  end do

                  call rmvnorm(q,workvb1,ztz,workmh2,workvb2,theta)

                  do j=1,q
                     bclus(evali,j)=theta(j)
                  end do
                  
               end if
            end if


c++++++++++ subject in cluster with only 1 observation
             
            if(ns.eq.1)then
                
               since=ss(i)

               if(since.lt.ncluster)then
                   call relabel(i,since,nsubject,q,ncluster,
     &                          cstrt,ccluster,ss,bclus,theta)
               end if
                
               ccluster(ncluster)=ccluster(ncluster)-1 
               ncluster=ncluster-1

               do j=1,ncluster
                  tmp3=0.d0
                  tmp2=0.d0
                  do k=1,ni
                     tmp1=0.d0
                     do l=1,q
                        tmp1=tmp1+z(datastr(i,k+1),l)*bclus(j,l)
                     end do
                     
                     sigma2e=lambda(datastr(i,k+1))
                     
                     tmp2=tmp2+log(sigma2e)                     
                     
                     tmp1=res(datastr(i,k+1))-tmp1
                     
                     tmp3=tmp3+tmp1*tmp1/sigma2e
                  end do

                  tmp1=-(dble(ni)*log(tpi))

                  prob(j)=exp(log(dble(ccluster(j)))+
     &                        (tmp1-tmp2-tmp3)/2.d0)
     
               end do

               do j=1,ni
                  tmp1=0.d0
                  do k=1,q
                     tmp1=tmp1+z(datastr(i,j+1),k)*mu(k)
                  end do
                  ywork(j)=res(datastr(i,j+1))-tmp1
               end do

               do j=1,ni
                  do k=1,q
                     tmp1=0.d0
                     do l=1,q
                        tmp1=tmp1+z(datastr(i,j+1),l)*sigma(l,k)   
                     end do
                     workk1(j,k)=tmp1
                  end do
               end do
        
               do j=1,ni
                  do k=1,ni
                     tmp1=0.d0
                     do l=1,q
                       tmp1=tmp1+workk1(j,l)*z(datastr(i,k+1),l)
                     end do
                     workkm1(j,k)=tmp1
                  end do
               end do

               do j=1,ni
                  sigma2e=lambda(datastr(i,j+1))
                  workkm1(j,j)=workkm1(j,j)+sigma2e
               end do

               call invdet2(workkm1,maxni,ni,workkm2,detlog,iflag2,
     &                      workkv1)

               tmp1=-(dble(ni)*log(tpi))
               tmp2=detlog

               tmp3=0.d0
               do j=1,ni
                  do k=1,ni
                     tmp3=tmp3+ywork(j)*workkm2(j,k)*ywork(k)
                  end do
               end do
               
               prob(ncluster+1)=exp(log(alpha)+(tmp1-tmp2-tmp3)/2.d0)


               call simdisc(prob,nsubject+1,ncluster+1,evali)
               
               ss(i)=evali
               
               ccluster(evali)=ccluster(evali)+1

               cstrt(evali,ccluster(evali))=i
               
               if(evali.gt.ncluster)then
                  ncluster=ncluster+1
                  
                  do j=1,q
                     do k=1,q
                        tmp1=0.d0
                        do l=1,ni
                           sigma2e=lambda(datastr(i,l+1))
                           tmp1=tmp1+z(datastr(i,l+1),j)*
     &                          z(datastr(i,l+1),k)/sigma2e
                        end do
                        ztz(j,k)=tmp1
                     end do
                  end do

                  do j=1,q
                     do k=1,q
                        ztz(j,k)=ztz(j,k)+sigmainv(j,k)
                     end do
                  end do   
 
                  call inverse(ztz,q,iflagb)                   
                  
                  do j=1,q
                     tmp1=0.d0
                     do k=1,ni
                        sigma2e=lambda(datastr(i,k+1))
                        
                        tmp1=tmp1+z(datastr(i,k+1),j)*
     &                        res(datastr(i,k+1))/sigma2e
                     end do
                     zty(j)=tmp1
                  end do
                  
                  do j=1,q
                     tmp1=0.d0
                     do k=1,q
                        tmp1=tmp1+sigmainv(j,k)*mu(k)   
                     end do
                     zty(j)=zty(j)+tmp1
                  end do
                  
                  do j=1,q
                     tmp1=0.d0
                     do k=1,q
                        tmp1=tmp1+ztz(j,k)*zty(k) 
                     end do
                     workvb1(j)=tmp1
                  end do

                  call rmvnorm(q,workvb1,ztz,workmh2,workvb2,theta)

                  do j=1,q
                     bclus(evali,j)=theta(j)
                  end do
                  
               end if
            end if

         end do


c++++++++++++++++++++++++++++++
c+++++++ b) Resampling step
c++++++++++++++++++++++++++++++

         do ii=1,ncluster

c++++++++++ check if the user has requested an interrupt
            call rchkusr()

            do i=1,q
               do j=1,q
                  ztz(i,j)=0.d0
               end do
               zty(i)=0.d0
            end do

            ns=ccluster(ii)

            do i=1,ns
               ni=datastr(cstrt(ii,i),1) 
               
               do j=1,q
                  do k=1,q
                     tmp1=0.d0
                     do l=1,ni
                        tmp1=tmp1+z(datastr(cstrt(ii,i),l+1),j)*
     &                            z(datastr(cstrt(ii,i),l+1),k)
                     end do
                     ztz(j,k)=ztz(j,k)+tmp1
                  end do
               end do
               
               do j=1,q
                  tmp1=0.d0
                  do k=1,ni
                     tmp1=tmp1+z(datastr(cstrt(ii,i),k+1),j)*
     &                         res(datastr(cstrt(ii,i),k+1))
                  end do
                  zty(j)=zty(j)+tmp1
               end do                  
            end do
            
            do i=1,q
               do j=1,q
                  ztz(i,j)=ztz(i,j)/sigma2e+sigmainv(i,j)
               end do
            end do

            call inverse(ztz,q,iflagb)                   
            
            do i=1,q
               tmp1=0.d0
               do j=1,q
                  tmp1=tmp1+sigmainv(i,j)*mu(j)   
               end do
               zty(i)=zty(i)/sigma2e+tmp1
            end do
            
            do i=1,q
               tmp1=0.d0
               do j=1,q
                  tmp1=tmp1+ztz(i,j)*zty(j) 
               end do
               workvb1(i)=tmp1
            end do
            
            call rmvnorm(q,workvb1,ztz,workmh2,workvb2,theta)

            do i=1,q
               bclus(ii,i)=theta(i)
            end do
            
            do i=1,ns
               do j=1,q
                  b(cstrt(ii,i),j)=theta(j)
               end do
            end do
         end do


c+++++++++++++++++++++++++++++++++++         
c+++++++ update the scale parameter
c+++++++++++++++++++++++++++++++++++

         do i=1,nrec

c++++++++++ check if the user has requested an interrupt
            call rchkusr()
            
            tmp1=0.d0
            do j=1,q
               tmp1=tmp1+z(i,j)*b(subject(i),j) 
            end do
            res(i)=res(i)-tmp1
            
            tmp2=res(i)
            tmp1=0.d0
            
            call samplamb(tmp2,tmp1)
            
            lambda(i)=tmp1
         end do
         
c++++++++++++++++++++++++++++++++++         
c+++++++ Base line distribution
c++++++++++++++++++++++++++++++++++

c+++++++ check if the user has requested an interrupt
         call rchkusr()

         if(murand.eq.1)then
            do i=1,q
               workvb1(i)=smu(i)
               do j=1,q
                  workb1(i,j)=(sigmainv(i,j)*dble(ncluster))+psiinv(i,j)
               end do
            end do

            call invdet(workb1,q,workb2,detlog,iflagb,workvb2)

            do i=1,ncluster
               do j=1,q
                  tmp1=0.d0
                  do k=1,q
                     tmp1=tmp1+sigmainv(j,k)*bclus(i,k)
                  end do
                  workvb1(j)=workvb1(j)+tmp1
               end do
            end do
     
            do i=1,q
               workvb2(i)=0.d0
            end do
     
            do i=1,q
               tmp1=0.d0
               do j=1,q
                  tmp1=tmp1+workb2(i,j)*workvb1(j)
               end do
               workvb2(i)=tmp1
            end do
          
            call rmvnorm(q,workvb2,workb2,workmh2,workvb1,theta)

            do i=1,q
               mu(i)=theta(i)
            end do
         end if

c+++++++ check if the user has requested an interrupt
         call rchkusr()

         if(sigmarand.eq.1)then          
            do i=1,q
               do j=1,q
                  quadf(i,j)=0.d0
               end do
            end do
         
            do i=1,ncluster
               do j=1,q
                  do k=1,q
                     quadf(j,k)=quadf(j,k)+               
     &                          (bclus(i,j)-mu(j))*(bclus(i,k)-mu(k))
                   end do
               end do
            end do

            do i=1,q
               do j=1,q
                  quadf(i,j)=quadf(i,j)+tinv(i,j)
               end do
            end do


            call riwishart(q,nu0+ncluster,quadf,workb1,workb2,workvb1,
     &                     workmh2,workmh3,iflagb)

            do i=1,q
               do j=1,q
                  sigma(i,j)=quadf(i,j)
                  sigmainv(i,j)=workb1(i,j)
               end do
            end do
         end if   

c++++++++++++++++++++++++++++++++++         
c+++++++ Precision parameter
c++++++++++++++++++++++++++++++++++
         if(aa0.gt.0.d0)then
            call samalph(alpha,aa0,ab0,ncluster,nsubject)
         end if 


c++++++++++++++++++++++++++++++++++         
c+++++++ save samples
c++++++++++++++++++++++++++++++++++         
         
         if(iscan.gt.nburn)then
            skipcount=skipcount+1
            if(skipcount.gt.nskip)then
               isave=isave+1
               dispcount=dispcount+1

c+++++++++++++ random effects
               k=0
               do i=1,nsubject
                  do j=1,q
                     bsave(i,j)=bsave(i,j)+b(i,j)                  
                     k=k+1
                     randsave(isave,k)=b(i,j)
                  end do   
               end do

c+++++++++++++ predictive information

               do i=1,ncluster
                  prob(i)=dble(ccluster(i))/(alpha+dble(nsubject))
               end do
               prob(ncluster+1)=alpha/(alpha+dble(nsubject))

               call simdisc(prob,nsubject+1,ncluster+1,evali)
               
               if(evali.le.ncluster)then
                  do j=1,q
                     theta(j)=bclus(evali,j)
                  end do
               end if
               if(evali.gt.ncluster)then
                  call rmvnorm(q,mu,sigma,workmh2,workvb2,theta)
               end if
               
               do i=1,q
                  k=k+1
                  randsave(isave,k)=theta(i) 
               end do

c+++++++++++++ functional parameters
               
               tmp1=rbeta(1.d0,alpha+dble(nsubject))
               do i=1,q
                  betar(i)=tmp1*theta(i)
               end do
               tmp2=tmp1
               weight=(1.d0-tmp1)
               
               do while((1.d0-tmp2).gt.eps)
                  tmp3=rbeta(1.d0,alpha+dble(nsubject))
                  tmp1=weight*tmp3
                  weight=weight*(1.d0-tmp3)

                  do i=1,ncluster
                     prob(i)=dble(ccluster(i))/(alpha+dble(nsubject))
                  end do
                  prob(ncluster+1)=alpha/(alpha+dble(nsubject))

                  call simdisc(prob,nsubject+1,ncluster+1,evali)
               
                  if(evali.le.ncluster)then
                     do j=1,q
                        theta(j)=bclus(evali,j)
                     end do
                  end if
                  if(evali.gt.ncluster)then
                     call rmvnorm(q,mu,sigma,workmh2,workvb2,theta)
                  end if

                  do i=1,q
                     betar(i)=betar(i)+tmp1*theta(i)
                  end do
                  tmp2=tmp2+tmp1
               end do

               do i=1,ncluster
                  prob(i)=dble(ccluster(i))/(alpha+dble(nsubject))
               end do
               prob(ncluster+1)=alpha/(alpha+dble(nsubject))

               call simdisc(prob,nsubject+1,ncluster+1,evali)
               
               if(evali.le.ncluster)then
                  do j=1,q
                     theta(j)=bclus(evali,j)
                  end do
               end if
               if(evali.gt.ncluster)then
                  call rmvnorm(q,mu,sigma,workmh2,workvb2,theta)
               end if
               
               tmp1=weight

               do i=1,q
                  betar(i)=betar(i)+tmp1*theta(i)
               end do

c+++++++++++++ regression coefficients

               do i=1,q
                  thetasave(isave,i)=betar(i)
               end do

               if(nfixed.gt.0)then
                  do i=1,p
                     thetasave(isave,q+i)=beta(i)
                     betasave(i)=betasave(i)+beta(i)
                  end do
               end if   

c+++++++++++++ baseline mean

               do i=1,q
                  thetasave(isave,q+nfixed+i)=mu(i)
               end do

c+++++++++++++ baseline covariance

               k=0
               do i=1,q
                  do j=i,q
                     k=k+1
                     thetasave(isave,q+nfixed+q+k)=sigma(i,j)
                  end do
               end do

c+++++++++++++ cluster information
               k=(q*(q+1)/2)  
               thetasave(isave,q+nfixed+q+k+1)=ncluster
               thetasave(isave,q+nfixed+q+k+2)=alpha

c+++++++++++++ cpo
               dbarc=0.d0
               do i=1,nrec
                  tmp1=0.d0
                  if(nfixed.gt.0)then
                     do j=1,p
                        tmp1=tmp1+x(i,j)*beta(j)
                     end do
                  end if   
                  do j=1,q
                     tmp1=tmp1+z(i,j)*b(subject(i),j)
                  end do
                  tmp2=exp(tmp1)/(1.d0+exp(tmp1))
                  tmp3=dbin(dble(yr(i)),1.d0,tmp2,0) 
                  cpo(i,1)=cpo(i,1)+1.0d0/tmp3
                  cpo(i,2)=cpo(i,2)+tmp3                  
                  
                  tmp3=dbin(dble(yr(i)),1.d0,tmp2,1) 
                  dbarc=dbarc+tmp3
               end do

c+++++++++++++ dic
               dbar=dbar-2.d0*dbarc
               
c+++++++++++++ print
               skipcount = 0
               if(dispcount.ge.ndisplay)then
                  call cpu_time(sec1)
                  sec00=sec00+(sec1-sec0)
                  sec=sec00
                  sec0=sec1
                  tmp1=sprint(isave,nsave,sec)
                  dispcount=0
               end if   
            end if
         end if   

      end do
      
      do i=1,nrec
         cpo(i,1)=dble(nsave)/cpo(i,1)
         cpo(i,2)=cpo(i,2)/dble(nsave)
      end do
            
      do i=1,p
         betasave(i)=betasave(i)/dble(nsave)
      end do

      do i=1,nsubject
         do j=1,q
            bsave(i,j)=bsave(i,j)/dble(nsave)
         end do
      end do   

      dhat=0.d0
      lpml=0.d0
      do i=1,nrec
         tmp1=0.d0
         if(nfixed.gt.0)then
            do j=1,p
               tmp1=tmp1+x(i,j)*betasave(j)
            end do
         end if   
         do j=1,q
            tmp1=tmp1+z(i,j)*bsave(subject(i),j)
         end do
         tmp2=exp(tmp1)/(1.d0+exp(tmp1))
         
         dhat=dhat+dbin(dble(yr(i)),1.d0,tmp2,1) 
         lpml=lpml+log(cpo(i,1))
      end do
      dhat=-2.d0*dhat      

      dbar=dbar/dble(nsave)
      pd=dbar-dhat
      
      mc(1)=dbar
      mc(2)=dhat
      mc(3)=pd
      mc(4)=dbar+pd
      mc(5)=lpml
      
      return
      end
         

c=======================================================================   
      subroutine samplamb(r,eval)
c=======================================================================
c     generate the scale parameter for a logistic distribution
c     A.J.V., 2006
      implicit none
      integer ok,rint,llint
      double precision r,eval,rnorm
      double precision y,u,tmp1
      real runif
      
      ok=0
      eval=0.d0
      r=sqrt((r**2))
      
      do while(ok.eq.0)
         y=rnorm(0.d0,1.d0)
         y=y*y
         y=1+(y-sqrt(y*(4.d0*r+y)))/(2.d0*r)
         u=dble(runif())
         
         tmp1=1.d0/(1.d0+y)
         if(u.le.tmp1)eval=r/y
         if(u.gt.tmp1)eval=r*y
         
         u=dble(runif())
         
         if(eval.gt.(4.d0/3.d0))then
            ok=rint(u,eval)
         end if

         if(eval.le.(4.d0/3.d0))then
            ok=llint(u,eval)
         end if
      end do
      return
      end
      
c=======================================================================   
      integer function rint(u,eval)
c=======================================================================   
c     A.J.V., 2006
      implicit none
      integer j,pot
      double precision u,eval,z,x
      
      z=1.d0
      x=exp(-0.5d0*eval)
      
      j=0
      
1     j=j+1
      
      pot=(j+1)**2
      
      z=z-dble(pot)*(x**(pot-1))
      
      if(z.gt.u)then
        rint=1
        go to 2
      end if
      
      j=j+1
      pot=(j+1)**2
      z=z+dble(pot)*(x**(pot-1))

      if(z.lt.u)then
        rint=0
        go to 2
      end if
      
      go to 1

2     continue
      
      return
      end
      
      
c=======================================================================   
      integer function llint(u,eval)
c=======================================================================   
c     A.J.V., 2006
      implicit none
      integer j,pot
      double precision u,eval
      double precision h,frst,tlpi,pi2,iu,z,x,k,tmp1
      
      parameter(frst=0.34657359027997264d0)
      parameter(tlpi=2.8618247146235003d0)
      parameter(pi2=9.869604401089358d0)

      h=frst+tlpi-2.5d0*log(eval)-0.5d0*pi2/eval+0.5d0*eval
      iu=log(u)
      z=1.d0
      
      x=exp(-0.5d0*pi2/eval)
      
      k=eval/pi2
      
      j=0

1     j=j+1      

      pot=((j)**2)-1
      
      z=z-k*x**(pot)
      
      tmp1=h+log(z)

      if(tmp1.gt.iu)then
        llint=1
        go to 2
      end if

      j=j+1
      pot=((j+1)**2)
      
      z=z+dble(pot)*(x**(pot-1))

      tmp1=h+log(z)
      
      if(tmp1.lt.iu)then
        llint=0
        go to 2
      end if
      
      go to 1
      
2     continue
      
      return
      end
      
                  
