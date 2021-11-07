%% test walk-based network centrality
clear; clc
load sub103818_TEST1_LR.mat
A = OMST;
A(A~=0) = 1;
A = A + A';
spy(A)

%% SFC
W1 = ccs_core_graphwalk(A,1); wSFC1 = full(W1(52,:));
W5 = ccs_core_graphwalk(A,5); wSFC5 = full(W5(52,:))/max(full(W5(52,:)));
W9 = ccs_core_graphwalk(A,9); wSFC9 = full(W9(52,:))/max(full(W9(52,:)));
W13 = ccs_core_graphwalk(A,13); wSFC13 = full(W13(52,:))/max(full(W13(52,:)));
W17 = ccs_core_graphwalk(A,17); wSFC17 = full(W17(52,:))/max(full(W17(52,:)));
W21 = ccs_core_graphwalk(A,21); wSFC21 = full(W21(52,:))/max(full(W21(52,:)));
W25 = ccs_core_graphwalk(A,25); wSFC25 = full(W25(52,:))/max(full(W25(52,:)));

%% SFC with NBTW
P1 = ccs_core_graphnbtw(A,1); pSFC1 = full(P1(52,:));
P5 = ccs_core_graphnbtw(A,5); pSFC5 = full(P5(52,:))/max(full(P5(52,:)));
P9 = ccs_core_graphnbtw(A,9); pSFC9 = full(P9(52,:))/max(full(P9(52,:)));
P13 = ccs_core_graphnbtw(A,13); pSFC13 = full(P13(52,:))/max(full(P13(52,:)));
P17 = ccs_core_graphnbtw(A,17); pSFC17 = full(P17(52,:))/max(full(P17(52,:)));
P21 = ccs_core_graphnbtw(A,21); pSFC21 = full(P21(52,:))/max(full(P21(52,:)));
P25 = ccs_core_graphnbtw(A,25); pSFC25 = full(P25(52,:))/max(full(P25(52,:)));