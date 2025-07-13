library(ggplot2)
library(ggtext)

bed_colnames = c("chr", "start", "end", "name", "score", "strand")
source("~/setThemePoster.R")
args = commandArgs(trailingOnly = TRUE)
# args = c("niebs_hg38_full_chain_intersect.bed",
#          "niebs_mm39_full_chain_intersect.bed",
#          "hg38_full_chain.bed",
#          "mm39_full_chain.bed",
#          "total_size_hg38.tsv",
#          "gc_chains_hg38.tsv",
#          "gc_chains_mm39.tsv",
#          "plot_cov_hg38_mm39_full_chains.png")

xlab_label = "*Species 1* coverage"
ylab_label = "*Species 2* coverage"
if (length(args) > 5) {
  xlab_label = args[6]
  ylab_label = args[7]
}

species1_intersect = read.delim(args[1],
                                header = FALSE,
                                col.names = bed_colnames)
species2_intersect = read.delim(args[2],
                                header = FALSE,
                                col.names = bed_colnames)

chains_species1 = read.delim(args[3],
                             header = FALSE,
                             col.names = bed_colnames)
chains_species2 = read.delim(args[4],
                             header = FALSE,
                             col.names = bed_colnames)

col_sizes = c("id", "size")

species1_intersect$len = species1_intersect$end - species1_intersect$start
species2_intersect$len = species2_intersect$end - species2_intersect$start
chains_species1$len = chains_species1$end - chains_species1$start
chains_species2$len = chains_species2$end - chains_species2$start

agg_block_species1 = aggregate(chains_species1$len,
                               by = list(chains_species1$name),
                               FUN = sum)
agg_block_species2 = aggregate(chains_species2$len,
                               by = list(chains_species2$name),
                               FUN = sum)
agg_intersect_species1 = aggregate(species1_intersect$len,
                                   by = list(species1_intersect$name),
                                   FUN = sum)
agg_intersect_species2 = aggregate(species2_intersect$len,
                                   by = list(species2_intersect$name),
                                   FUN = sum)
agg_block_species1$cov =
  agg_intersect_species1[match(agg_block_species1$Group.1,
                               agg_intersect_species1$Group.1),
                         "x"] / agg_block_species1$x
agg_block_species2$cov =
  agg_intersect_species2[match(agg_block_species2$Group.1,
                               agg_intersect_species2$Group.1),
                         "x"] / agg_block_species2$x

final_df = agg_block_species1[agg_block_species1$x > 50000,
                              c("Group.1", "cov", "x")]
colnames(final_df) = c("name", "species1_cov", "species1_size")
final_df$species2_cov =
  agg_block_species2[match(final_df$name,
                           agg_block_species2$Group.1), "cov"]
final_df$species2_size =
  agg_block_species2[match(final_df$name,
                           agg_block_species2$Group.1), "x"]

head(final_df[is.na(final_df$species2_cov) & !is.na(final_df$species1_cov), ])
head(final_df[is.na(final_df$species1_cov) & !is.na(final_df$species2_cov), ])

final_df = final_df[!is.na(final_df$species2_cov) &
                    !is.na(final_df$species1_cov), ]
# use Total Least Squares to find the best fit line
matrix = prcomp(final_df[, c("species2_cov", "species1_cov")])$rotation
beta = matrix[2, 1] / matrix[1, 1]

intercept = mean(final_df$species2_cov) - beta * mean(final_df$species1_cov)

print(beta)
print(cor.test(final_df$species1_cov,
               final_df$species2_cov)$p.value)

plot = ggplot() +
  geom_point(data = final_df,
             aes(x = species1_cov, y = species2_cov),
             alpha = 0.1) +
  geom_line(aes(x = seq(0,
                        0.2, by = 0.01),
                y = (seq(0,
                         0.2, by = 0.01) *
                beta + intercept))) +
  xlab(xlab_label) +
  ylab(ylab_label) +
  xlim(0, 0.2) +
  ylim(0, 0.2) +
  theme_poster +
  theme(axis.title.x = element_markdown(),
        axis.title.y = element_markdown())
ggsave(args[5], height = 10, width = 10)