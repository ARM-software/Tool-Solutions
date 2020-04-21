#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#if DEBUG
#define RATINGS_F "test.title.ratings.tsv"
#define BASICS_F "test.title.basics.tsv"
#define OUT_F "test.title.sorted.tsv"
#else
#define RATINGS_F "title.ratings.tsv"
#define BASICS_F "title.basics.tsv"
#define OUT_F "title.sorted.tsv"
#endif

typedef struct {
  char *id;
  char *title;
  float score;
} movie;


int compare_movies(const void *a, const void *b)
{
  float a_score = ((movie *)a)->score;
  float b_score = ((movie *)b)->score;

  return ( a_score < b_score );
}


int main()
{
  FILE *fin_ratings, *fin_movies, *fout;
  movie *table = NULL;
  int i;
  // Number of elements in titles, scores, ids
  int n_movies = 0;

  fin_ratings = fopen(RATINGS_F, "r");
  fin_movies = fopen(BASICS_F, "r");
  fout = fopen(OUT_F, "w+");

  if(fin_ratings == NULL || fin_movies == NULL || fout == NULL)
  {
    printf("Error, could not open file\n");
    // Close files
    fclose(fin_ratings);
    fclose(fin_movies);
    fclose(fout);
    return -1;
  }

  // Read the title file
  char *t_buffer =NULL;
  size_t t_len = 0;
  while( getline(&t_buffer, &t_len, fin_movies) != -1 )
  {
    char *t_id = strtok(t_buffer, "\t");
    char *type = strtok(NULL, "\t");
    if(strcmp(type, "movie") == 0)
    {
      char *title = strtok(NULL, "\t");
      n_movies++;
      // Allocate
      movie *tmp_table = (movie*)realloc(table, n_movies*sizeof(movie));
      // Record data
      if(tmp_table != NULL)
      {
        table = tmp_table;
        table[n_movies-1].id = (char*)malloc((strlen(t_id)+1)*sizeof(char));
        table[n_movies-1].title = (char*)malloc((strlen(title)+1)*sizeof(char));
        table[n_movies-1].score = 0.0;
        if(table[n_movies-1].id != NULL && table[n_movies-1].title != NULL )
        {
          strcpy(table[n_movies-1].id,t_id);
          strcpy(table[n_movies-1].title,title);
        }
        else
          printf("Error allocating memory\n");
      }
      else
        printf("Error allocating memory\n");
    }
  }

  // Read the ratings file
  char *r_buffer = NULL;
  size_t r_len = 0;
  int last_found=0; // last found id
  i=0; // position of id
  while( getline(&r_buffer, &r_len, fin_ratings) != -1 )
  {
    char *r_id = strtok(r_buffer, "\t");
    // Compute and store score only if this is a movie
    bool found = false;
    // Browse movie IDs until found
    while(i < n_movies && !found)
    {
      //if(strcmp(table[i].id,r_id) == 0) 
      if(memcmp(table[i].id, r_id, 9*sizeof(char)) == 0) // faster
      {
        found = true;
        last_found = i;
      }
      else
        i++;
    }
    // If movie compute score
    if(found)
    {
      char *rating = strtok(NULL, "\t");
      char *votes = strtok(NULL, "\t");
      // Record
      table[i].score = (float)atof(rating)*atof(votes);
    }
    else
    {
      //i=0; // reset 
      i=last_found; // faster
    }
  }

  // Close input files
  fclose(fin_ratings);
  fclose(fin_movies);

  // Sort
  qsort(table, n_movies, sizeof(movie), compare_movies);

  // Write out the data
  i=0;
  while(i < n_movies)
  {
    // Print only if rated
    if(table[i].score > 0.00)
      fprintf(fout, "%s\t%.2f\t%s\n", table[i].id, table[i].score, table[i].title);

    // Deallocate
    free(table[i].id);
    free(table[i].title);

    i++;
  }

  if(table != NULL)
    free(table);

  fclose(fout);

  return 0;
}
