args = commandArgs(trailingOnly = TRUE)

bed_colnames = c("chr", "start", "end", "name", "score", "strand")
data = read.delim(args[1],
                  header = FALSE,
                  col.names = bed_colnames)

data[data$strand == "+", "zero"] = data[data$strand == "+", "start"]
data[data$strand == "-", "zero"] = data[data$strand == "-", "end"]
data$name = paste0(data$name, "_", data$start, "_", data$end)
write.table(data,
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE,
            file = args[2],
            sep = "\t")