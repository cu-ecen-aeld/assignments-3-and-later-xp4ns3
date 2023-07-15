#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param) {
	printf("Running threadfunc()\n");
	
	struct thread_data *data = (struct thread_data *)thread_param;
	usleep(data->w_time);
	pthread_mutex_lock(data->mutex);
	
	printf("Locked!\n");

	usleep(data->r_time);
	data->thread_complete_success = true;

	printf("thread_complete_success is true\n");

	pthread_mutex_unlock(data->mutex);

	printf("Unlocked!\n");
	printf("Exiting threadfunc()\n");
	
	return data;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms) {
	int ret;
	
	struct thread_data *data = malloc(sizeof(struct thread_data));
	if (!data) {
		return false;
	}

	data->mutex = mutex;		
	data->w_time = wait_to_obtain_ms;
	data->r_time = wait_to_release_ms;
	data->thread_complete_success = false;

	printf("Going to run pthread_create()\n");
	
	ret = pthread_create(thread, NULL, threadfunc, data);	
	if (ret) {
		printf("%d\n", errno);
		free(data);
		return false;
	}

	printf("Successfully created thread %p\n", thread);

	/*
	ret = pthread_join(*thread, NULL);
	if (ret) {
		printf("%d\n", errno);
		return false;
	}

	printf("Successfully joined with %p; returned value was %d\n", thread, data->thread_complete_success);
	*/
	/*
	if (data->thread_complete_success == false) {

		printf("thread_complete_success is false\n");
		
		return false;
	} 

	printf("thread_complete_success is true\n");
	*/

	return true;
}
