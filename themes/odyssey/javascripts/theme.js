/* Nothing here yet */


(function (window, document, undefined) {
    window.onload = function windowLoad() {
        console.log("The window loaded.");

        var searchButton = document.querySelector('.js-search-box');
        var searchForm = document.querySelector('.js-search-form');
        var searchInput = document.querySelector('.js-search-input');
        searchButton.addEventListener('click', function () {
            searchButton.classList.toggle('is-open');
            searchForm.classList.toggle('is-open');
        });
    };
}(window, document));