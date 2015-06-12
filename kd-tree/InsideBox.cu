//
//  InsideBox.cu
//  
//
//  Created by Ann-Christine Vossberg on 6/3/15.
//
//

#include <stdio.h>
#include <iostream>
//#include "cuPrintf.cu" braucht es?
#include "InsideBox.hpp"


// Here you can set the device ID that was assigned to you
#define MYDEVICE 0

// Simple utility function to check for CUDA runtime errors
void checkCUDAError(const char *msg);


//think about: threadIDx.y!! index s.d. threadIDx.y die treeArray_y bearbeitet -
//for this would have to change treeArray_x & treeArray_y etc --> tree..
__global__
void insideBox( int *treeArray_x, int *treeArray_y, int *treeArray_z, int *treeArray_ID, int *box)
{
    //braucht kein d_result.
    //Kann in treeArray_ID returned werden -1, wenn nicht insideBox
    int warpSize = 32;
    int warpIdx = threadIdx.x / warpSize;
    int i = warpIdx;
    int j = threadIdx.x % 32; //=0 bis 32
    int treeSize = warpSize-1;
    int index = i*treeSize+j;
    
    
    if( ((treeArray_x[index] >= box[0] && treeArray_x[index] <= box[1]) || (box[0] == 0 && box[1] == 0))  && ((treeArray_y[index] >= box[2] && treeArray_y[index] <= box[3]) || (box[2] == 0 && box[3] == 0)) && ((treeArray_z[index] >= box[4] && treeArray_z[index] <= box[5]) || (box[4] == 0 && box[5] == 0))){
        //inside box
        
    }
        else{
            //printf("not inside box");
        treeArray_ID[index] = -1;
    }
}

void cudaMain(int number_of_trees, int tree_size, int treeArray_x[], int treeArray_y[], int treeArray_z[], int treeArray_ID[], int box[]){
    
    cudaSetDevice(MYDEVICE);
    std::cout << "number of trees: " << number_of_trees << std::endl;
    std::cout << "tree size: " << tree_size << std::endl;
    
    //TODO: int ----> num_t
    int size_of_forest = number_of_trees*tree_size*sizeof(int);
    int *d_treeArray_x;
    int *d_treeArray_y;
    int *d_treeArray_z;
    int *d_treeArray_ID;
    int *d_box;
    
    
    //allocate memory
    cudaMalloc(&d_treeArray_x, size_of_forest);
    cudaMalloc(&d_treeArray_y, size_of_forest);
    cudaMalloc(&d_treeArray_z, size_of_forest);
    cudaMalloc(&d_treeArray_ID, size_of_forest);
    //TODO: generic
    cudaMalloc(&d_box, 6*sizeof(int));
    
    //send trees to gpu
    cudaMemcpy(d_treeArray_x, treeArray_x, size_of_forest, cudaMemcpyHostToDevice);
    cudaMemcpy(d_treeArray_y, treeArray_y, size_of_forest, cudaMemcpyHostToDevice);
    cudaMemcpy(d_treeArray_z, treeArray_z, size_of_forest, cudaMemcpyHostToDevice);
    cudaMemcpy(d_treeArray_ID, treeArray_ID, size_of_forest, cudaMemcpyHostToDevice);
    //TODO: generic
    cudaMemcpy(d_box, box, 6*sizeof(int), cudaMemcpyHostToDevice);
    
    
    //search forest for points inside box_dimensions - returns all treeArray_ID's which are inside box - rest are filled with -1
    insideBox<<<1,1024>>>(d_treeArray_x, d_treeArray_y, d_treeArray_z, d_treeArray_ID, d_box);
    
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess)
        printf("Error: %s\n", cudaGetErrorString(err));
    
    cudaMemcpy(treeArray_ID, d_treeArray_ID, size_of_forest, cudaMemcpyDeviceToHost);
    
    
    std::cout << "Size of forest: " << size_of_forest << std::endl;
    //print out ID's which are in box:
    for(int i = 0; i< number_of_trees*tree_size; i++){
        std::cout << "ID: " << treeArray_ID[i]<< std::endl;
    }
    
    
    //free space
    cudaFree(d_treeArray_x);
    cudaFree(d_treeArray_y);
    cudaFree(d_treeArray_z);
    cudaFree(d_treeArray_ID);
    cudaFree(d_box);

}
