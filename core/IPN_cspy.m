function IPN_cspy(S,arg2,arg3)
%SPY Visualize sparsity pattern.
%   SPY(S) plots the sparsity pattern of the matrix S.
%
%   SPY(S,'LineSpec') uses the color and marker from the line
%   specification string 'LineSpec' (See PLOT for possibilities).
%
%   SPY(S,markersize) uses the specified marker size instead of
%   a size which depends upon the figure size and the matrix order.
%
%   SPY(S,'LineSpec',markersize) sets both.
%
%   SPY(S,markersize,'LineSpec') also works.

%   Copyright 1984-2004 The MathWorks, Inc. 
%   $Revision: 5.19.4.3 $  $Date: 2004/07/05 17:01:42 $
%Modifier: xinian.zuo@nyumc, $Date: 2010/10/27 13:34 $

cax = newplot;
next = lower(get(cax,'NextPlot'));
hold_state = ishold;

marker = ''; color = ''; markersize = 0; linestyle = 'none';
if nargin >= 2
   if ischar(arg2), 
      [line,color,marker,msg] = colstyle(arg2);
      if ~isempty(msg)
         error('MATLAB:spy:InvalidLinespecString', msg)
      end
   else
      markersize = arg2;
   end
end
if nargin >= 3
   if ischar(arg3),
      [line,color,marker,msg] = colstyle(arg3); 
      if ~isempty(msg)
         error('MATLAB:spy:InvalidLinespecString', msg)
      end
   else
      markersize = arg3;
   end
end
if isempty(marker), marker = '.'; end
if isempty(color), co = get(cax,'colororder'); color = co(1,:); end

if nargin < 1, S = defaultspy; end
[m,n] = size(S);
if marker~='.' && markersize==0,
   markersize = get(gcf,'defaultlinemarkersize');
end
if markersize == 0
   units = get(gca,'units');
   set(gca,'units','points');
   pos = get(gca,'position');
   markersize = max(4,min(14,round(6*min(pos(3:4))/max(m+1,n+1))));
   set(gca,'units',units);
end

[i,j, k] = find(S);
if isempty(i), i = NaN; j = NaN; end
if isempty(S), marker = 'none'; end
scatter(j, i, markersize, k, 'filled')

xlabel(['nz = ' int2str(nnz(S))]);
set(gca,'xlim',[0 n+1],'ylim',[0 m+1],'ydir','reverse', ...
   'grid','none','plotboxaspectratio',[n+1 m+1 1]);

if ~hold_state, set(cax,'NextPlot',next); end

% ------------------------------------------------------

function S = defaultspy
c = [';@3EA4:aei7]ced.CFHE;4\T>*Y>,dL0,HOQQMJLJE9PX[[Q.ZF.\JTCA1dd'
     '<A;FB:;bfj8^df//DGIF<5]UF+ZH-eM>-IorRPNMPIE-Y\\R8[I8]SUDW2e+'
     '=4BGC;<cgk9_e00DEOJG=6^VG,[I.fN?5jpsSQPNQPF.Z,]S9`S9cTWVX:+,'
     ':5CHD<=4hlh`f11EFPKHA7&WH-\J/gOC?kqtTRRORQJ8--^TB+T=dWYWY;,_'
     ';6D3E=>7imiag2IFOQLID8''XI.]K0"PD@l32UZhP//P988_WC,U>+Z^Y\<2`'
     '<82BF>?8jnjbhLJGPRMJE9/YJ/`L1#QMC$;;V[iv09QE99,XD.YB,[_\]=3a'
     '>9;CG?@9kokc2MKHQSOKF:0ZL0aM2$RNG%AAW\jw9E.FEE-_G8aG.d`]_W5+'
     '?:CDH@A:lpld3NLIRTPLG=1[M1bN3%SOH4BBX]kx:J9LLL8`H9bJ/+d_dX6,'
     '@;DEIAB;mqmePOMJSUQMJ>2\N2cO4&TPP@HCY^lyDKEMMN9+I@+S8,+deY7^'
     '8@EFJBC<4rnfQPNPTVRNKB3]O3dP5''UQQCIDZ_mzEPFNNOE,RA,T9/,++\8_'
     '9A2G3CD=544gRQPQUWUOLE4^P4"Q6(VRRIJE[`n{KQKOOPK-SE.W:F/,,]Z+'
     ':BDH4DE>655hSRQRVXVPMF5_Q5#R>)eSSJKF\ao0L.L-WUL.VF8XCH001_[,'
     ';3EI<EO?766iTSRSWYWQNG6$R6''S?*fTTlLQ]bp1M/P.XVP8[H9]DIDA=`\]'
     '?4D3=FP@877jUTSTXZXROK7%S7(TF+gUUmMR^cq:N9Q8YZQ9_I>cIJEB>d_^'
     '@5E@>GQA98b3VUTUY*YSPL8&T>)UI,hVhnNS_dr;PE.9Z[RCaR?+JTFC?e`+'
     '79FA?HRB:9c4WVUVZ+ZWQM=,WG*VJ-"gi4OT`es<QL9E[\TD+SA,SWUVW+d,'
     '8:3B@JSX;:dVXWVW[,[XRN>-XH+bK.#hj@PUvftDRMEF,]UH,UB.TYVWX,e\'
     '9;ECAKTY<;eWYXWX\:)YSOE.YI,cL/$ikCqV1guE/PFL-^XI-YG/WZWXY1+]'
     ':AFDBLUZ=<fXZYXY,;*ZTPF/ZJ-dM0%j#Jrt2hxH0QKM8,YJ.ZI8[^YY\2,,'
     ';B3ECMV[>jgY[ZYZ-<7[XQG0[K.eN1&"$K2u:iyO9.PN9-_K8aJ9\_]\]82['
     '?CEFDNW\?khZ\[Z[==8\YRH1\M/!O2''#%m31Bw0PE/QXE8+R9bS;da^]_93\'
     '@2FGEOX]ali[]\[\>>9(ZSL2]N0"P3($&n;2Cx1QN9--L9,SA+T<+d__`:4,'
     'A3GHFPY^bmj\^]\]??:)[TM3^O1%Q4)%''oA:D0:0OE.8ME-TE,XB,+`da;5['
     '643IGQZ_cnk]_^]^@@;5\UN4_P2&R6*&(3B;E1<1PN99NL8WF.^C/,a+bY6,'
     '7:F3HR[`dol^`_^_AA<6]VO5`Q3''S>+'');CBF:=:QOEEOO9_G8aH6/d,cZ[Y'
     '8;G4IS\aep4_a`_-BD=7''XP6aR4(T?,(5@DCHCC;RPFLPPD`H9bJ70+0d\\Z'
     '9BH>JT^bf45`ba`.CE@8(YQ7#S5)UD-)?AEDIDDD/QKMVQJ+S?cSDF,1e]a,'
     ':C3?K4_cg5[acbaADFA92ZR8$T6*VE.*@JFEJEEE0.NNWTK,U@+TEG0?+_bX'
     ';2D@L9`dh6\bdcbBEGD:3[S=)U7+cK/+CKGFLIKI9/OWZUL-VA,WIHB@,`cY'];
i = double(c(:)-32);
j = cumsum(diff([0; i])<=0) + 1;
S = sparse(i,j,1)';
