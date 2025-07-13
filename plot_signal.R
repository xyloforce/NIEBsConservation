library(stringr)
library(ggplot2)
library(zoo)

args = commandArgs(trailingOnly = TRUE)
min_size = as.numeric(args[4])
max_size = as.numeric(args[5])
lab_first = "Species 1"
lab_second = "Species 2"
if (length(args) > 5) {
  lab_first = args[6]
  lab_second = args[7]
}

cum_sum_counts = function(count_vector) {
  count_vector = count_vector - mean(count_vector)
  summed_vector = cumsum(count_vector)
  return(summed_vector)
}

agg_count = function(data, ids, window_size = 50000) {
  data$max_size = as.numeric(data$end_chain) - as.numeric(data$start_chain)
  data$max_windows = data$max_size / window_size

  data$rounded_pos = round(data$pos / window_size) *
    window_size

  agg_data = aggregate(data$count,
                       by = list(data$chain_id,
                                 data$rounded_pos),
                       FUN = sum)
  colnames(agg_data) = c("chain_id", "pos", "count")

  final_df = lapply(ids, function(id) {
    tmp = data.frame(
      id = id,
      pos = seq(0,
                data[match(id,
                           data$chain_id),
                     "max_size"] + window_size,
                by = window_size),
      count = 0
    )
    subset = agg_data[agg_data$chain_id == id, ]
    indexes = match(paste(subset$chain_id, subset$pos),
                    paste(tmp$id, tmp$pos))
    tmp[indexes, "count"] = subset$count
    return(tmp)
  })

  final_df = do.call(rbind, final_df)
  return(final_df)
}

data = read.delim(args[1],
                  header = FALSE,
                  col.names = c("id", "pos", "count"))
data[, c("chain_id",
         "start_chain",
         "end_chain")] = str_split_fixed(data$id, "_", 3)

data2 = read.delim(args[2],
                   header = FALSE,
                   col.names = c("id", "pos", "count"))
data2[, c("chain_id",
          "start_chain",
          "end_chain")] = str_split_fixed(data2$id, "_", 3)

print(paste("max pos species 1 :", max(data$pos)))
print(paste("max pos species 2 :", max(data2$pos)))

max_pos = aggregate(data$pos,
                    by = list(data$chain_id),
                    FUN = max)
max_pos2 = aggregate(data2$pos,
                     by = list(data2$chain_id),
                     FUN = max)
colnames(max_pos) = c("chain_id", "max_pos")
colnames(max_pos2) = c("chain_id", "max_pos")
max_sizes = min_size:max_size
selected_id = max_pos[max_pos$max_pos %in% max_sizes,
                      "chain_id"]
selected_id2 = max_pos2[max_pos2$max_pos %in% max_sizes,
                        "chain_id"]
selected_id = selected_id[selected_id %in% selected_id2][1:3]

factor_from_size = 20
agg_species1 = agg_count(data,
                    ids = selected_id,
                    window_size = min_size / factor_from_size)

agg_species1 = lapply(agg_species1$id,
                 function(id) {
                   correct_counts =
                     cum_sum_counts(agg_species1[agg_species1$id == id, "count"])
                   return(data.frame(id = id,
                                     pos = agg_species1[agg_species1$id == id, "pos"],
                                     count = agg_species1[agg_species1$id == id, "count"],
                                     cumcount = correct_counts))
                 })
agg_species1 = do.call(rbind, agg_species1)

agg_species2 = agg_count(data2,
                      ids = selected_id,
                      window_size = min_size / factor_from_size)
agg_species2 = lapply(agg_species2$id,
                   function(id) {
                     correct_counts =
                       cum_sum_counts(agg_species2[agg_species2$id == id, "count"])
                     return(data.frame(id = id,
                                       pos =
                                         agg_species2[agg_species2$id == id, "pos"],
                                       count =
                                         agg_species2[agg_species2$id == id, "count"],
                                       cumcount = correct_counts))
                   })
agg_species2 = do.call(rbind, agg_species2)

agg_species1$species = lab_first
agg_species2$species = lab_second
final_df = rbind(agg_species1, agg_species2)

# head(final_df)
# labels = c(lab_first, lab_second)
# names(labels) = unique(final_df$species)

plot = ggplot(final_df,
              aes(x = pos, y = cumcount, color = species)) +
  geom_point() +
  facet_grid(rows = vars(species),
             cols = vars(id),
             scales = "free_x",
             labeller = labeller(species = labels)) +
  labs(title = "Count per Position for Each Chain",
       x = "Position (in kb)",
       y = "Count") +
  scale_color_hue(labels = c(lab_first,
                             lab_second)) +
  theme_minimal()

ggsave(args[3], width = 16)