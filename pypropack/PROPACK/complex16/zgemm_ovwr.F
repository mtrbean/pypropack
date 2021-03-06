c
c     (C) Rasmus Munk Larsen, Stanford University, 2004
c


      subroutine zdgemm_ovwr_left(transb,m,n,k,A,lda,B,ldb,zwork,lzwork)
c     
c     compute  A <- A*op(B)
c
      implicit none
      character*1 transb
      integer m,n,k,lda,ldb,lzwork
      complex*16 A(lda,*),zwork(lzwork)
      double precision B(ldb,*)
      integer i,j,l,blocksize

      if((m.le.0).or.(n.le.0).or.(k.le.0)) return
      if (lzwork.lt.n) stop 'Too little workspace in ZDGEMM_OVWR_LEFT'
      blocksize = int(lzwork/n)
      i = 1
      do i=1,m-blocksize+1,blocksize
         call zdgemm(transb,blocksize,n,k, A(i,1),lda,
     c              B,ldb,zwork,blocksize)
         do j=0,n-1
            do l=0,blocksize-1
               A(i+l,j+1) = zwork(j*blocksize+1+l)
            enddo
         enddo
      enddo
      blocksize = m-i+1
      call zdgemm(transb,blocksize,n,k,A(i,1),lda,
     c           B,ldb,zwork,blocksize)
      do j=0,n-1
         do l=0,blocksize-1
            A(i+l,j+1) = zwork(j*(m-i+1)+1+l)
         enddo
      enddo
      return
      end

      subroutine  zdgemm(transb,m,n,k,A,lda,B,ldb,C,ldc)
      implicit none
      character*1 transb
      integer m,n,k,lda,ldb,ldc
      complex*16 A(lda,*), C(ldc,*)
      double precision B(ldb,*),btmp
      integer i,j,l

      do i=1,m
         do j=1,n
            C(i,j) = dcmplx(0d0,0d0)
         enddo
      enddo
      do l=1,k
         do j=1,n
            do i=1,m
               C(i,j) = C(i,j) + A(i,l)*B(j,l)
            enddo
         enddo
      enddo
      end


      subroutine  zdgemmblk(A,lda,B,ldb,C,ldc)
      implicit none
      integer blksz
      parameter (blksz=96)
      integer lda,ldb,ldc
      complex*16 A(lda,blksz), C(ldc,blksz)
      double precision B(ldb,blksz)
      integer i,j,l, i2,j2,l2

      do l=1,blksz
         do j=1,blksz
            do i=1,blksz
               C(i,j) = dcmplx(dreal(A(i,l))*B(j,l)+dreal(C(i,j)),
     c              dimag(A(i,l))*B(j,l)+dimag(C(i,j)))
            enddo
         enddo
      enddo
      end


      subroutine  zdgemm1(transb,m,n,k,A,lda,B,ldb,C,ldc)
c     
c     compute C = A * OP(B)
c     
      implicit none
      character*1 transb
      integer m,n,k,lda,ldb,ldc
      complex*16 A(lda,*), C(ldc,*)
      double precision B(ldb,*)

      integer blksz
      parameter (blksz=96)
      integer i,j,l,iblk,jblk,lblk
      complex*16 CC(blksz,blksz)
      double precision BB(blksz,blksz),btmp
      common/BBcom/BB,CC
      logical lsame
      external lsame

      if (lsame('T',transb)) then
c
c     C = A*B^T
c        
c     Comment: This manually blocked version runs at ~1.15 GFlops 
c     on a 3 GHz Pentium 4. Not very impressive.
c     Even worse on an 1.3 GHz Itanium2: 400 MFlops - awful!
c
         do lblk=1,k-blksz+1,blksz
            do jblk=1,n-blksz+1,blksz
               do l=1,blksz
                  do j=1,blksz
                     BB(j,l) = B(jblk-1+j,lblk-1+l)
                  enddo
               enddo
               do iblk=1,m-blksz+1,blksz
                  if (lblk.eq.1) then
                     do j=jblk,jblk+blksz-1
                        do i=iblk,iblk+blksz-1
                           C(i,j) = dcmplx(0d0,0d0)
                        enddo
                     enddo
                  endif
                  call zdgemmblk(A(iblk,lblk),lda,BB,blksz,
     c                 C(iblk,jblk),ldc)
               enddo
c     
c     clean up loops for i
c     
               if (lblk.eq.1) then
                  do j=jblk,jblk+blksz-1
                     do i=iblk,m
                        C(i,j) = dcmplx(0d0,0d0)
                     enddo
                  enddo
               endif
               do l=lblk,lblk+blksz-1
                  do j=jblk,jblk+blksz-1
                     btmp = B(j,l)
                     do i=iblk,m
                        C(i,j) =  dcmplx(
     c                       dreal(A(i,l))*btmp+dreal(C(i,j)),
     c                       dimag(A(i,l))*btmp+dimag(C(i,j)))
                     enddo
                  enddo
               enddo
            enddo
c     
c     clean up loops for j
c     
            if (lblk.eq.1) then
               do j=jblk,n
                  do i=1,m
                     C(i,j) = dcmplx(0d0,0d0)
                  enddo
               enddo
            endif
            do l=lblk,lblk+blksz-1
               do j=jblk,n
                  btmp = B(j,l)
                  do i=1,m
                     C(i,j) =  dcmplx(
     c                    dreal(A(i,l))*btmp+dreal(C(i,j)),
     c                    dimag(A(i,l))*btmp+dimag(C(i,j)))
                  enddo
               enddo
            enddo 
         enddo
c     
c     clean up loop for l
c     
         do l=lblk,k
            if (l.eq.1) then
               do j=1,n
                  do i=1,m
                     C(i,j) = dcmplx(0d0,0d0)
                  enddo
               enddo      
            endif
            do jblk=1,n-blksz+1,blksz
               do iblk=1,m-blksz+1,blksz
                  do j=jblk,jblk+blksz-1
                     btmp = B(j,l)
                     do i=iblk,iblk+blksz-1
                     C(i,j) =  dcmplx(
     c                    dreal(A(i,l))*btmp+dreal(C(i,j)),
     c                    dimag(A(i,l))*btmp+dimag(C(i,j)))
                     enddo
                  enddo
               enddo
               do j=jblk,jblk+blksz-1
                  btmp = B(j,l)
                  do i=iblk,m
                     C(i,j) =  dcmplx(
     c                    dreal(A(i,l))*btmp+dreal(C(i,j)),
     c                    dimag(A(i,l))*btmp+dimag(C(i,j)))
                  enddo
               enddo               
            enddo
            do j=jblk,n
               btmp = B(j,l)
               do i=1,m
                      C(i,j) =  dcmplx(
     c                    dreal(A(i,l))*btmp+dreal(C(i,j)),
     c                    dimag(A(i,l))*btmp+dimag(C(i,j)))
               enddo
            enddo
         enddo
      else

c
c     C = A*B
c        
         do iblk=1,m-blksz+1,blksz
            do jblk=1,n-blksz+1,blksz
               do j=1,blksz
                  do i=1,blksz
                     CC(i,j) = dcmplx(0d0,0d0)
                  enddo
               enddo
               do j=1,blksz
                  do l=1,k
                     do i=1,blksz
                        CC(i,j) = A(iblk-1+i,l)*B(l,jblk-1+j) + CC(i,j)
                     enddo
                  enddo
               enddo
               do j=1,blksz
                  do i=1,blksz
                     C(iblk-1+i,jblk-1+j) = CC(i,j)
                  enddo
               enddo            
            enddo
            do j=jblk,n
               do i=iblk,iblk+blksz-1
                  C(i,j) = dcmplx(0d0,0d0)
               enddo
            enddo
c     
c     clean up loop for j
c     
            do j=jblk,n
               do l=1,k
                  do i=iblk,iblk+blksz-1
                     C(i,j) = A(i,l)*B(l,j) + C(i,j)
                  enddo
               enddo
            enddo 
         enddo
         do j=1,n
            do i=iblk,m
               C(i,j) = dcmplx(0d0,0d0)
            enddo
         enddo
c     
c     clean up loop for i
c     
         do j=1,n
            do l=1,k
               do i=iblk,m
                  C(i,j) = A(i,l)*B(l,j) + C(i,j)
               enddo
            enddo
         enddo
      endif
      end

      

