clc;
clear;

%%
load('delta.mat','trend','cons_v','region_fixed_v','time_fixed_v','time_fixed_v_median','date','pop');
load('beta.mat','beta','gamma_mean');
load('dynamics.mat','i_current_gen','i_stock_gen','s_current_gen');

Pfizer_w=0.4775;
Moderna_w=0.5225;

Pfizer_e1=0.52;
Moderna_e1=0.921;
Pfizer_e2=0.946;
Moderna_e2=0.941;

shooting=2;  % we adopt the efficiency of 1st or 2nd dose

if shooting==1
    Pfizer_e=Pfizer_e1;
    Moderna_e=Moderna_e1;
end
if shooting==2
    Pfizer_e=Pfizer_e2;
    Moderna_e=Moderna_e2;
end

eff=Pfizer_w*Pfizer_e+Moderna_w*Moderna_e;

T=200;
region=51;

steps=100;
vac=linspace(0.0003,0.003,steps+1);

%%
index=nan(steps+1,2);

i_stock_final=zeros(1,steps+1);

for j=1:steps+1
    delta=zeros(region,length(date));
    for i=14:length(date)
        delta(:,i)=max(0,cons_v+vac(j)*(i-13)+region_fixed_v+time_fixed_v(i-13));
    end
    delta=[delta zeros(region,T)];
    for i=length(date)+1:length(date)+T
        delta(:,i)=max(0,cons_v+vac(j)*(i-13)+region_fixed_v+time_fixed_v_median);
    end
    
    i_current_gen=[i_current_gen zeros(region,T)];
    i_stock_gen=[i_stock_gen zeros(region,T)];
    s_current_gen=[s_current_gen zeros(region,T)];
    
    vaccine=zeros(region,length(date)+T);
    
    for i=1:region
        for k=14:length(date)+T
            if vaccine(i,k-1)+delta(i,k)<s_current_gen(i,13)
                vaccine(i,k)=vaccine(i,k-1)+delta(i,k);
            else
                vaccine(i,k)=s_current_gen(i,13);
                delta(i,k)=s_current_gen(i,13)-vaccine(i,k-1);
            end
        end
    end
    
    for i=14:length(date)+T
        i_current_gen(:,i)=i_current_gen(:,i-1).*(1+beta(:,i-1).*s_current_gen(:,i-1)-gamma_mean);
        i_stock_gen(:,i)=i_current_gen(:,i).*beta(:,i-1).*s_current_gen(:,i-1)+i_stock_gen(:,i-1);
        s_current_gen(:,i)=max(0,s_current_gen(:,i-1)-i_current_gen(:,i).*beta(:,i-1).*s_current_gen(:,i-1)-eff*delta(:,i-1));
    end
    i_stock_final(j)=pop'*i_stock_gen(:,120)/sum(pop);
    
    vaccine_share=pop'*vaccine/sum(pop);
    
    rt=beta(:,1:length(date)+T).*s_current_gen(:,1:length(date)+T);
    for i=1:length(date)+T
        rt(:,i)=rt(:,i)./gamma_mean;
    end
    
    r_order=zeros(1,length(date)+T);
    for i=1:length(date)+T
        r_order(i)=i_current_gen(:,i)'*rt(:,i)/sum(i_current_gen(:,i));
    end
    
    ranking=3;
    
    r_order=maxk(rt,ranking);
    r_order=r_order(ranking,:);
    
    for k=length(date)+T:-1:1
        if r_order(k)>1
            index(j,1)=k+1;
            index(j,2)=vaccine_share(k+1);
            break;
        end
    end
end

%% Figure of vaccination

g1=index(:,1)';
g4=index(:,2)';

% generate a series of date

t_start=datetime([2020,10,12]);
t_series=dateshift(t_start,'dayofweek',2,1:150);
t_series_str=datestr(t_series,'ddmmmyy');

fit_coef_1=polyfit(vac,g1,5);
fit_val_1=polyval(fit_coef_1,vac);
fit_coef_2=polyfit(vac,g4,5);
fit_val_2=polyval(fit_coef_2,vac);

figure;
hold on;
[AX,H1,H2]=plotyy(vac,[fit_val_1],vac,[fit_val_2],'plot');
set(AX(1),'XColor','k','YColor','k');  
set(AX(2),'XColor','k','YColor','k'); 
set(AX(1),'ylim',[25 55],'ytick',25:5:55,'yticklabel',t_series_str(25:5:55,:),'xlim',[vac(1)-2e-4 vac(length(vac))+2e-4]); 
set(AX(2),'ylim',[0.3 0.6],'ytick',0.3:0.05:0.6,'xlim',[vac(1)-2e-4 vac(length(vac))+2e-4]);  
set(AX(1),'box','off')
set(AX(2),'box','off')
set(H1(1),'LineStyle','-','Linewidth',2,'color','r');
set(H2(1),'LineStyle','-','Linewidth',2,'color','b');
line([trend trend],[30 50],'Linewidth',1,'Linestyle','-.','color','k');
text(trend,50,'Current Trend=1.85e-3');
legend([H1(1),H2(1)],{'Herd Immunity','Cumulative Vaccination Coverage'},'Location', 'Best');
xlabel('Vaccination Trend');
title('a','Position',[vac(1)-2e-4-3.6e-4,55.8],'FontSize',15)

%% Figure of i_stock share

g1=index(:,1)';
g4=i_stock_final;

fit_coef_1=polyfit(vac,g1,5);
fit_val_1=polyval(fit_coef_1,vac);
fit_coef_2=polyfit(vac,g4,5);
fit_val_2=polyval(fit_coef_2,vac);

figure;
hold on;
[AX,H1,H2]=plotyy(vac,[fit_val_1],vac,[fit_val_2],'plot');
set(AX(1),'XColor','k','YColor','k');  
set(AX(2),'XColor','k','YColor','k'); 
set(AX(1),'ylim',[25 55],'ytick',25:5:55,'yticklabel',t_series_str(25:5:55,:),'xlim',[vac(1)-2e-4 vac(length(vac))+2e-4]); 
set(AX(2),'ylim',[0.1 0.2],'ytick',0.1:0.02:0.2,'xlim',[vac(1)-2e-4 vac(length(vac))+2e-4]); 
set(AX(1),'box','off')
set(AX(2),'box','off')
set(H1(1),'LineStyle','-','Linewidth',2,'color','r');
set(H2(1),'LineStyle','-','Linewidth',2,'color','b');
line([trend trend],[30 40],'Linewidth',1,'Linestyle','-.','color','k');
text(trend,40,'Current Trend=1.85e-3');
legend([H1(1),H2(1)],{'Herd Immunity','Cumulative Infection Rate'},'Location', 'Best');
xlabel('Vaccination Trend');
title('b','Position',[vac(1)-2e-4-3.6e-4,55.8],'FontSize',15)
