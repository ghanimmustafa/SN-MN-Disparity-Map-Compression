
DELTAs = [0,1,3,7,15,31,63];
LINE_WIDTH = 4;
method = 'MN';
load(strcat(method,'_unfilteredDMs_avg_SpaceSavings_per_delta.mat'))
average_space_savings = average_space_savings(DELTAs+1);
unfiltered_SS = average_space_savings;
hold on
plot(DELTAs,unfiltered_SS,'LineWidth',LINE_WIDTH);
%plot(DELTAs,unfiltered_SS,'r*');
hold off
hold on
load(strcat(method,'_filteredDMs_avg_SpaceSavings_per_delta.mat'))
average_space_savings = average_space_savings(DELTAs+1);

filtered_SS = average_space_savings;

plot(DELTAs,filtered_SS,'LineWidth',LINE_WIDTH);
hold off
load(strcat(method,'_integer_GTs_avg_SpaceSavings_per_delta.mat'))
average_space_savings = average_space_savings(DELTAs+1);

groundTruth_SS = average_space_savings;
hold on
plot(DELTAs,groundTruth_SS,'LineWidth',LINE_WIDTH);
hold off

%xticks(DELTAs)
%xticklabels({'0','1','3'})
xlabel('Compression Threshold (\delta)','FontSize',15,'Position',[35 -25])
ylabel('Space Savings (%)','FontSize',15,'Position',[-2 30]);




legend({'Unfiltered DMs','Median filtered DMs','Ground truth DMs'},'FontSize',14);
set(gca,'FontWeight','bold')
set(gca,'XTick',0:5:65)
set(gca,'YTick',-20:5:80)
set(gca,'XLim',[0 68])
set(gca,'YLim',[-20 83])

set(gca,'TickLength',[0 .01])
set(get(gca,'ylabel'),'rotation',90)
set(gcf, 'WindowState', 'maximized');

exportgraphics(gcf,strcat(method,'_varying_delta.jpg'),"Resolution",500);