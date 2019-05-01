subroutine libxc(rhoup,gxu,gyu,gzu,ggxu,ggyu,ggzu,g2rhoup,tauup, &
                       rhodn,gxd,gyd,gzd,ggxd,ggyd,ggzd,g2rhodn,taudn, &
                       ggx,ggy,ggz,grhoggrho,exc,vxcup,vxcdn,jspin,id_func)
#ifdef LIBXC
      use xcparam, only : xcconst
      use xc_f03_lib_m

      implicit none

      TYPE(xc_f03_func_t) :: xc_func
      TYPE(xc_f03_func_info_t) :: xc_info

      integer, intent(in) :: jspin, id_func

      real*8, intent(in) :: &
         rhoup, gxu, gyu, gzu, ggxu, ggyu, ggzu, g2rhoup, tauup, &
         rhodn, gxd, gyd, gzd, ggxd, ggyd, ggzd, g2rhodn, taudn, &
         ggx, ggy, ggz, grhoggrho

      real*8, intent(inout) :: exc(1), vxcup, vxcdn

      real*8 :: grho2, grhoup2, grhodn2, grhoupdn, &
         grhoupggrhoup, grhodnggrhodn, grhoupggrhodn, grhodnggrhoup, &
         grhoupggrho, grhodnggrho, &
         gsigma1grhoup, gsigma2grhoup, gsigma3grhoup, &
         gsigma1grhodn, gsigma2grhodn, gsigma3grhodn, &
         rho(2), sigma(3), lapl_rho(2), tau(2), &
         vrho(2), vsigma(3), vlapl_rho(2), vtau(2), &
         v2rho2(3), v2rhosigma(6), v2sigma2(6), &
         f1, f2, f3, f4, xcconstvec(1)

      vrho(:) = 0.0d0
      vsigma(:) = 0.0d0
      vlapl_rho(:) = 0.0d0
      vtau(:) = 0.0d0
      v2rho2(:) = 0.0d0
      v2rhosigma(:) = 0.0d0
      v2sigma2(:) = 0.0d0

      if (jspin .eq. 1) then

         call xc_f03_func_init(xc_func,id_func,XC_UNPOLARIZED)
         xc_info = xc_f03_func_get_info(xc_func)

         if (id_func .eq. 208) then
            xcconstvec(1) = xcconst
            call xc_f03_func_set_ext_params(xc_func,xcconstvec)
         endif

         select case(xc_f03_func_info_get_family(xc_info))

         case (xc_family_lda)

            rho(1) = rhoup + rhodn

            call xc_f03_lda_exc_vxc(xc_func,1,rho(1),exc(1),vrho(1))

            vxcup = vrho(1)
            vxcdn = vxcup

         case (xc_family_gga,xc_family_hyb_gga)

            rho(1) = rhoup + rhodn

            sigma(1) = (gxu+gxd)**2 + (gyu+gyd)**2 + (gzu+gzd)**2

            if ((id_func .eq. 160) .or. (id_func .eq. 182)) then

               call xc_f03_gga_vxc(xc_func,1,rho(1),sigma(1),vrho(1),vsigma(1))
               exc(1) = 0.0d0
               vxcup = vrho(1)
               vxcdn = vxcup

            else

               call xc_f03_gga_exc_vxc(xc_func,1,rho(1),sigma(1),exc(1),vrho(1),vsigma(1))
               call xc_f03_gga_fxc(xc_func,1,rho(1),sigma(1),v2rho2(1),v2rhosigma(1),v2sigma2(1))

               vxcup = vrho(1) - 2.0d0*v2rhosigma(1)*sigma(1) - &
                  4.0d0*v2sigma2(1)*sqrt(sigma(1))*grhoggrho - &
                  2.0d0*vsigma(1)*(g2rhoup+g2rhodn)
               vxcdn = vxcup

            endif

         case (xc_family_mgga,xc_family_hyb_mgga)

            rho(1) = rhoup + rhodn

            sigma(1) = (gxu+gxd)**2 + (gyu+gyd)**2 + (gzu+gzd)**2

            lapl_rho(1) = g2rhoup + g2rhodn

            tau(1) = max(tauup+taudn,sigma(1)/(8.0d0*rho(1)))

            if ((id_func .eq. 207) .or. (id_func .eq. 208) .or. (id_func .eq. 209)) then
               call xc_f03_mgga_vxc(xc_func,1,rho(1),sigma(1),lapl_rho(1),tau(1), &
                  vrho(1),vsigma(1),vlapl_rho(1),vtau(1))
               exc(1) = 0.0d0
               vxcup = vrho(1)
               vxcdn = vxcup
            else
               call xc_f03_mgga_exc(xc_func,1,rho(1),sigma(1),lapl_rho(1),tau(1),exc(1))
               vxcup = 0.0d0
               vxcdn = 0.0d0
            endif

         end select

      elseif (jspin .eq. 2) then

         call xc_f03_func_init(xc_func,id_func,XC_POLARIZED)
         xc_info = xc_f03_func_get_info(xc_func)

         if (id_func .eq. 208) then
            xcconstvec(1) = xcconst
            call xc_f03_func_set_ext_params(xc_func,xcconstvec)
         endif

         select case(xc_f03_func_info_get_family(xc_info))

         case (xc_family_lda)

            rho(1) = rhoup
            rho(2) = rhodn

            call xc_f03_lda_exc_vxc(xc_func,1,rho(1),exc(1),vrho(1))

            vxcup = vrho(1)
            vxcdn = vrho(2)

         case (xc_family_gga,xc_family_hyb_gga)

            grho2 = (gxu+gxd)**2 + (gyu+gyd)**2 + (gzu+gzd)**2
            grhoup2 = gxu**2 + gyu**2 + gzu**2
            grhodn2 = gxd**2 + gyd**2 + gzd**2
            grhoupdn = gxu*gxd + gyu*gyd + gzu*gzd

            grhoupggrhoup = gxu*ggxu + gyu*ggyu + gzu*ggzu
            grhodnggrhodn = gxd*ggxd + gyd*ggyd + gzd*ggzd
            grhoupggrhodn = gxu*ggxd + gyu*ggyd + gzu*ggzd
            grhodnggrhoup = gxd*ggxu + gyd*ggyu + gzd*ggzu
            grhoupggrho = gxu*ggx + gyu*ggy + gzu*ggz
            grhodnggrho = gxd*ggx + gyd*ggy + gzd*ggz

            gsigma1grhoup = 2.0d0*sqrt(grhoup2)*grhoupggrhoup
            gsigma3grhoup = 2.0d0*sqrt(grhodn2)*grhoupggrhodn
            gsigma1grhodn = 2.0d0*sqrt(grhoup2)*grhodnggrhoup
            gsigma3grhodn = 2.0d0*sqrt(grhodn2)*grhodnggrhodn
            gsigma2grhoup = sqrt(grho2)*grhoupggrho - 0.5d0*(gsigma1grhoup + gsigma3grhoup)
            gsigma2grhodn = sqrt(grho2)*grhodnggrho - 0.5d0*(gsigma1grhodn + gsigma3grhodn)

            rho(1) = rhoup
            rho(2) = rhodn

            sigma(1) = grhoup2
            sigma(2) = grhoupdn
            sigma(3) = grhodn2

            if ((id_func .eq. 160) .or. (id_func .eq. 182)) then

               call xc_f03_gga_vxc(xc_func,1,rho(1),sigma(1),vrho(1),vsigma(1))
               exc(1) = 0.0d0
               vxcup = vrho(1)
               vxcdn = vrho(2)

            else

               call xc_f03_gga_exc_vxc(xc_func,1,rho(1),sigma(1),exc(1),vrho(1),vsigma(1))
               call xc_f03_gga_fxc(xc_func,1,rho(1),sigma(1),v2rho2(1),v2rhosigma(1),v2sigma2(1))

               f1 = 2.0d0*( &
                    v2rhosigma(1)*grhoup2 + &
                    v2rhosigma(4)*grhoupdn + &
                    v2sigma2(1)*gsigma1grhoup + &
                    v2sigma2(2)*gsigma2grhoup + &
                    v2sigma2(3)*gsigma3grhoup)

               f2 = 2.0d0*vsigma(1)*g2rhoup

               f3 = v2rhosigma(2)*grhoupdn + &
                    v2rhosigma(5)*grhodn2 + &
                    v2sigma2(2)*gsigma1grhodn + &
                    v2sigma2(4)*gsigma2grhodn + &
                    v2sigma2(5)*gsigma3grhodn

               f4 = vsigma(2)*g2rhodn

               vxcup = vrho(1) - f1 - f2 - f3 - f4

               f1 = 2.0d0*( &
                    v2rhosigma(6)*grhodn2 + &
                    v2rhosigma(3)*grhoupdn + &
                    v2sigma2(6)*gsigma3grhodn + &
                    v2sigma2(5)*gsigma2grhodn + &
                    v2sigma2(3)*gsigma1grhodn)

               f2 = 2.0d0*vsigma(3)*g2rhodn

               f3 = v2rhosigma(5)*grhoupdn + &
                    v2rhosigma(2)*grhoup2 + &
                    v2sigma2(5)*gsigma3grhoup + &
                    v2sigma2(4)*gsigma2grhoup + &
                    v2sigma2(2)*gsigma1grhoup

               f4 = vsigma(2)*g2rhoup

               vxcdn = vrho(2) - f1 - f2 - f3 - f4

            endif

         case (xc_family_mgga,xc_family_hyb_mgga)

            rho(1) = rhoup
            rho(2) = rhodn

            sigma(1) = gxu**2 + gyu**2 + gzu**2
            sigma(2) = gxu*gxd + gyu*gyd + gzu*gzd
            sigma(3) = gxd**2 + gyd**2 + gzd**2

            lapl_rho(1) = g2rhoup
            lapl_rho(2) = g2rhodn

            tau(1) = max(tauup,sigma(1)/(8.0d0*rho(1)))
            tau(2) = max(taudn,sigma(3)/(8.0d0*rho(2)))

            if ((id_func .eq. 207) .or. (id_func .eq. 208) .or. (id_func .eq. 209)) then
               call xc_f03_mgga_vxc(xc_func,1,rho(1),sigma(1),lapl_rho(1),tau(1), &
                  vrho(1),vsigma(1),vlapl_rho(1),vtau(1))
               exc(1) = 0.0d0
               vxcup = vrho(1)
               vxcdn = vrho(2)
            else
               call xc_f03_mgga_exc(xc_func,1,rho(1),sigma(1),lapl_rho(1),tau(1),exc(1))
               vxcup = 0.0d0
               vxcdn = 0.0d0
            endif

         end select

      endif

      call xc_f03_func_end(xc_func)

#endif
      end
