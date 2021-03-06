library(ggplot2)
library(ggthemes) ##
library(tidyverse)
#library(plyr)
library(reshape2)
library(colorspace)

## Eric's AUC gradient  
# Color scale with {colorspace}
nlevels = 100
AUC_colors <- diverge_hcl(
  n=nlevels,  # number of colors
  h = c(45, 225),  # Hues (low, hi)
  c = 100, # fixed Chroma or Chroma Range (edges, center)
  l = c(90, 10),  # Lightness range (edges, center) 
  power = 1  # exponent
)
names(AUC_colors) <- seq(0,1,1/(nlevels-1))

## Load and select data to be displayed
load("res.RData")
res <- res[which(res$bandwidth==35),]
res <- res[which(res$reporting_prob > 0.04),]
rep_prob_lvls <- levels(as.factor(res$reporting_prob))[c(12,1)]
neg_bin_k_lvls <- levels(as.factor(res$neg_bin_k))[c(3,1)]
inf_days_lvls <- levels(as.factor(res$infectious_days))[1]
agg_days_lvls <- levels(as.factor(res$aggregation_days))[1]

hl_data <- res %>%
  select_(.dots = names(.)[c(3,8,9,11,14:33)]) %>%
  filter(neg_bin_k %in% neg_bin_k_lvls) %>%
  filter(infectious_days == inf_days_lvls) %>%
  filter(aggregation_days == agg_days_lvls) %>%
  filter(reporting_prob %in% rep_prob_lvls) %>%
  melt(id.vars = names(.)[1:4], value.name = "AUC") %>%
  mutate(variable = as.factor(variable))

nrows <- nrow(hl_data)/2
hl_data$absAUC = abs(hl_data$AUC - 0.5)

hl_data <- hl_data %>%
  mutate(err = lead(variable,nrows), AUC_err = lead(AUC,nrows)) %>%
  filter(!is.na(err)) %>%
  mutate(reporting_prob =  factor(reporting_prob, levels(as.factor(.$reporting_prob))[c(2,1)])) %>%
  mutate(neg_bin_k = as.factor(neg_bin_k)) %>%
  droplevels()
new_levels <-  c("Mean", "Variance", "1st Diff. Var.", 
                 "Index of Dis.", "Autocovar.", "Autocorr.",
                 "Decay time", "Coeff. Var", "Skewness",
                 "Kurtosis")
hl_data$variable <- factor(hl_data$variable,levels(hl_data$variable)[c(6,1,2,7,3,4,5,8,9,10)])
levels(hl_data$variable) <- new_levels
levels(hl_data$reporting_prob) <- c("High reporting","Low reporting")
levels(hl_data$neg_bin_k) <- c("High overdispersion", "Low overdispersion")

#Define plotting function
hl_plot <- function(hl_data){
  ggplot(hl_data) + 
    geom_bar(aes(x=variable,y=absAUC, fill = AUC, color = AUC),stat="identity"  ) + 
    #labs(y = "|AUC - 0.5|") +
    facet_grid(reporting_prob~neg_bin_k) +
    geom_rangeframe(colour ="black") +
    scale_fill_gradientn(limits = c(0,1),colours=AUC_colors) +
    scale_color_gradientn(limits = c(0,1),colours=AUC_colors) +#+
    scale_y_continuous(name = "|AUC-0.5|",labels=c("0.0","0.1","0.2","0.3",
                                             "0.4","0.5"))
}


#par(fg = "#FF6AD5", bg = "#FFFFFF", col.lab = "#94D0FF",
#    col.main = "#C774E8", col.sub	= "#94D0FF",  col.axis = "#94D0FF",
#    font.lab = 3)

text_color <- "black"
background_color <- "white"
font_chosen <- "Times"

hl_plot(hl_data) +#theme_par() +
  theme(text = element_text(color=text_color, size = 14, family=font_chosen),
        title = element_text(size = 12),
        line = element_line(color=text_color),
        rect = element_rect(color="black"),
        axis.title.x=element_blank(),
        axis.title.y = element_text(color=text_color,face = "plain", 
                                    family=font_chosen, size = 10),
        axis.text.x = element_text(color = text_color, angle = 45,
                                   vjust = 1, hjust=1,family=font_chosen, size = 9),
        axis.text.y = element_text(color = text_color, family=font_chosen, size=9),
        axis.ticks = element_line(color=rgb(0,0,0,.25),line),
        axis.line = element_blank(),
        legend.text = element_text(color = text_color, family=font_chosen, size=9),
        legend.title = element_text(color = text_color, family = font_chosen, size=10),
        legend.margin=margin(t=0, r=0.1, b=0, l=-0.2, unit="cm"),
        panel.grid.major = element_blank(),
        panel.grid.major.y = element_line(color = rgb(0,0,0,.25)),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_rect(color=NA,fill=NA),
        panel.spacing = unit(1.2, "lines"),
        strip.text.y= element_text(color = text_color,angle = 270, family=font_chosen, size=10),
        strip.text.x= element_text(color = text_color, family=font_chosen, size=10),
        strip.background = element_rect(fill=NA),
        plot.background = element_rect(color=NA, fill=background_color),
        plot.margin = unit(c(0.0,0.0,0.1,0.1), "cm"))


ggsave("high-low.tiff",width =5.2 ,height=3, dpi = 300, units="in", compression="lzw")
