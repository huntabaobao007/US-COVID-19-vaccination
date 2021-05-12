clc;
clear;

%%  daily data input

region =51;

[daily_cases,~,~]=xlsread('cases_daily.xlsx');
[daily_vaccines,~,~]=xlsread('vaccines_daily.xlsx');
[state,state_name,state_raw]=xlsread('state.xlsx');
[pop,~,~]=xlsread('pop2019.xlsx');
pop(region+1)=[];

%% clean

i_daily=reshape(daily_cases(:,2),[],region);
v1_daily=reshape(daily_vaccines(:,1),[],region);
v2_daily=reshape(daily_vaccines(:,2),[],region);
i_US=sum(i_daily')/sum(pop);
v1_US=sum(v1_daily')/sum(pop);
v2_US=sum(v2_daily')/sum(pop);

v1_newly=zeros(1,length(v1_US)-1);
v2_newly=zeros(1,length(v1_US)-1);
for i=1:length(v1_US)-1
    v1_newly(i)=v1_US(i+1)-v1_US(i);
    v2_newly(i)=v2_US(i+1)-v2_US(i);
end

v1_newly=[nan(1,104),v1_newly,nan(1,12)];
v2_newly=[nan(1,104),v2_newly,nan(1,12)];
v1_US=[nan(1,103),v1_US,nan(1,12)];
v2_US=[nan(1,103),v2_US,nan(1,12)];
v1_US(138)=(v1_US(137)*v1_US(139))^0.5;
v2_US(138)=(v2_US(137)*v2_US(139))^0.5;

%% visualization

 x=12:158;             % range from 12-Oct-20 to 07-Mar-21

figure;
hold on;
[AX,H1,H2]=plotyy(x,[i_US(x)],x,[v1_US(x);v2_US(x)],'plot');
set(AX(1),'XColor','k','YColor','r');  
set(AX(2),'XColor','k','YColor','b'); 
HH1=get(AX(1),'Ylabel');
set(HH1,'String','Population Fraction Infected','color','r');
HH2=get(AX(2),'Ylabel');
set(HH2,'String','Cumulative Vaccination Coverage','color','b');
set(AX(1),'ylim',[1e-4 10e-4],'ytick',1e-4:1e-4:10e-4); 
set(H1(1),'LineStyle','-','Linewidth',2,'color','r');
set(H2(1),'LineStyle','-','Linewidth',2,'color','b');
set(H2(2),'LineStyle','--','Linewidth',2,'color','b');
set(AX(1),'box','off')
set(AX(2),'box','off')
set(gca,'xlim',[x(1),x(length(x))],'xtick',[x(1),x(length(x))],'xticklabel',{'12Oct20','07Mar21'})
legend([H1(1),H2(1),H2(2)],{'New Cases (left axis)','At Least 1 Dose (right axis)','Fully Vaccinated (right axis)'},'Location','Northwest');
xlabel('Date');
line([72 72],[3e-4 8e-4],'LineStyle','--','Linewidth',1,'color','k');
text(50,3e-4,{'December 11, 2020';'FDA issued EUA for Pfizer'});
line([79 79],[5e-4 9e-4],'LineStyle','--','Linewidth',1,'color','k');
text(79,8e-4,{'December 18, 2020';'FDA issued EUA for Moderna'});
line([124 124],[2.5e-4 6.5e-4],'LineStyle','--','Linewidth',1,'color','k');
text(124,6.5e-4,{'February 01, 2021';'More vaccinated than infected'});
line([150 150],[1e-4 4e-4],'LineStyle','--','Linewidth',1,'color','k');
text(150,4e-4,{'February 27, 2021';'FDA issued EUA for J&J'});
line([154 154],[1e-4 6e-4],'LineStyle','--','Linewidth',1,'color','k');
text(154,6e-4,{'March 03, 2021';'Biden announced plans of full vaccination';' by the end of May'});

